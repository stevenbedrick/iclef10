require 'nokogiri'
require 'typhoeus'
require 'enumerator'

#http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=11748933,11700088&retmode=xml

base_url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&email=bedricks%40ohsu.edu&id="

pmid_list = ActiveRecord::Base.connection.select_values('select distinct pmid from records where pmid is not null and pmid > 0 and pmid not in (select pmid from articles)')

puts "about to try and get #{pmid_list.size} articles"

count = 0

pmid_list.each do |pm|
  
  puts "on pmid: #{pm} (#{count}/#{pmid_list.size})"
  count += 1
  begin
    response = Typhoeus::Request.get(base_url + pm)
    puts base_url + pm
    # parse out the response:
    n = Nokogiri::XML(response.body)
    articles = n / "/PubmedArticleSet/PubmedArticle"

    articles.each do |a|

      # first things first; get the pmid:
      pmid_node = (a / "MedlineCitation/PMID")
      pmid = pmid_node.text
#      puts "got pmid: #{pmid}"

      title_node = (a / "MedlineCitation/Article/ArticleTitle")
      title = title_node.text
        puts title

      abstract_node = (a / "MedlineCitation/Article/Abstract/AbstractText")
      abstract = nil
      if not abstract_node.empty?
        abstract = abstract_node.text
      end

      # mesh terms:
      heading_list = (a / "MedlineCitation/MeshHeadingList/MeshHeading")
      headings = []
      if not heading_list.empty?
        heading_list.each do |h|
          this_heading = {}
          this_heading[:descriptor] = (h / 'DescriptorName').text
          this_heading[:major_topic] = false
          if not (h / "*[MajorTopicYN='Y']").empty?
            this_heading[:major_topic] = true
          end
          headings << this_heading
        end # ends for each heading
      end # ends if headings
  #      puts "headings: " + headings.join('; ')

      
      a = Article.new
      a.pmid = pmid
      a.title = title
      a.abstract = abstract
      
      puts "About to save \"#{a.title}\" (pmid: #{a.pmid})"
      
      #a.save

      headings.each do |h|
        am = AssignedMeshTerm.new(:article => a, :mesh_term => MeshTerm.find_or_create_by_term(h[:descriptor]))
        am.major_topic = h[:major_topic]
        #am.save
      end
      

    end # ends each article node 
  rescue Exception => e
    puts "couldn't get pmid: #{pm}: #{e.message}"
  end
  
end # ends each pmid

