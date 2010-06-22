require 'nokogiri'
require 'typhoeus'
require 'enumerator'

#http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=11748933,11700088&retmode=xml

base_url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&email=bedricks%40ohsu.edu&id="

pmid = ActiveRecord::Base.connection.select_values('select distinct pmid from records where pmid is not null and pmid > 0')

hydra = Typhoeus::Hydra.new(:max_concurrency => 5)

outlog = File.open('fetch_pmid.out','w')

pmid.each_slice(20) do |s|
  
  to_fetch = base_url + s.join(',')
  
  this_request = Typhoeus::Request.new(base_url + s.join(','))
  this_request.on_complete do |response|
    
    # dump the body somewhere:
    temp_out = File.open('./pm_out/' + s.join('_') + '.xml','w')
    temp_out.puts response.body
    temp_out.close
    
    
    # parse out the response:
    n = Nokogiri::XML(response.body)
    articles = n / "/PubmedArticleSet/PubmedArticle"
    
    articles.each do |a|
      
      title_node = (a / "MedlineCitation/Article/ArticleTitle")
      title = title_node.text
#      puts title
      
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
      a.title = title
      a.abstract = abstract
      
      headings.each do |h|
        am = AssignedMeshTerm.new(:article => a, :mesh_term => MeshTerm.find_or_create_by_term(h[:descriptor]))
        am.major_topic = h[:major_topic]
        am.save
      end
      
    end # ends each article
    
    outlog.puts("Another 20 down...")
    outlog.flush
  end # ends on_complete
  
  hydra.queue this_request
  
end


hydra.run

outlog.close