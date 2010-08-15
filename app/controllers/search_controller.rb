require 'ruby-debug'

class SearchController < ApplicationController
  
  skip_before_filter :verify_authenticity_token
  
  def index
    
  end
  
  def search

    
    @results = []

    #########display options############
    # @displayOp: how many results to return?
    @displayOp=(params['displayOp'])
    case @displayOp
       when 'a'
           @d=10
       when 'b'
           @d=25
       when 'c'
          @d=100
       when 'd'    
           @d=1000
       when 'e'    
           @d=100000
       else 
         @d=10
    end # ends case @displayOp
    
    # for pagination:
    # TODO: implement proper pagination
    #params[:p] = 1 unless params[:p]
    
    ######### query parsing parameters: ############
    @limitModality=(params['limitModality']) # do we try and guess the modality from the query?
    @reorder = params[:reorder]
    
    @modColumn = params[:mod_column] # which modality column to use? allowed vals: :title, :caption, :caption_title, :jaykc, :all
    @umlsSynonym=(params['umlsSynonym']) # use UMLS query expansion?
    @columnOp=(params['columnOp']) # which caption column to use?
    @titleOp=(params['titleOp']) # include titles, or just captions?
    @umls = params[:umlsSynonym]
    @stem_and_star = params[:stem_and_star] # stem and wildcard query terms?
    @unique = params[:unique_term] # only include unique terms after stemming/expansion?
    @parse_mode = params[:parseMode]
    
      
    # include mesh?
    @inc_mm_mh = params[:mm_mh]
    @inc_pm_mh = params[:pm_mh]
    @pm_major = params[:pm_major]
    
    # we're done getting raw parameters from query params, now let's do useful stuff with them:
    
    # set up configuration hash for query parser:
    parse_config_options = {
      :parse_mode => :simple_or,
      :limit_modality => false,
      :umls_synonym_expansion => false,
      :column_to_use => 'caption',
      :stem_and_star => @stem_and_star,
      :unique_terms => @unique,
      :add_title => false,
      :pubmed_mh => false,
      :pubmed_mh_major => false,
      :metamap_mh => false,
      :reorder => false
    }
     
    # what col to use?
    case @columnOp
      when 'a'
        parse_config_options[:column_to_use] = 'caption'
      else 'b'
        parse_config_options[:column_to_use] = 'parsed_caption'
    end # ends case @columnOp

    # which parse mode? choices are [:simple_and (a), :simple_or (o), :exact_match (e), :custom (p)]
    case @parse_mode
    when 'a'
      parse_config_options[:parse_mode] = :simple_and
    when 'o'
      parse_config_options[:parse_mode] = :simple_or
    when 'e'
      parse_config_options[:parse_mode] = :exact_match
    else
      parse_config_options[:parse_mode] = :custom
    end
    
    # include titles?
    if @titleOp == 't'
      parse_config_options[:add_title] = true
    end
    
    if @limitModality == 'lm'
      parse_config_options[:limit_modality] = true
    end
    
    if @reorder == 't'
      parse_config_options[:reorder] = true
    end
    
    #which modality column to use? allowed vals: :title, :caption, :caption_title, :jaykc, :all
    parse_config_options[:mod_column] = case @modColumn
    when 'title'
      :title
    when 'caption'
      :caption
    when 'caption_title'
      :caption_title
    when 'jaykc'
      :jaykc
    when 'all'
      :all
    else
      :caption
    end
    
    # umls?
    if @umls == 'umSy'
      parse_config_options[:umls_synonym_expansion] = true
    end
    
    # mesh?
    if @inc_mm_mh == 't'
      parse_config_options[:metamap_mh] = true
    end
    if @inc_pm_mh == 't'
      parse_config_options[:pubmed_mh] = true
      if @pm_major == 't'
        parse_config_options[:pubmed_mh_major] = true
      end
    end
    
    # stemming?
    if @stem_and_star == 'true'
      parse_config_options[:stem_and_star]= true
    end
    
    @opts = parse_config_options
    
    
    ##### output mode:
    ##### we can output results as either standard web view or as a TREC-formatted run file
    # possible values: 'trec' (trec-formatted output), 'std' (standard interactive output)
    @outOp=(params['outOp'])
    
    ##### when we're in TREC mode, users can enter a single query or a file full of a batch of queries
    # possible values: 'singleQ' (use @query_str), 'uplF' (look for params[:file] for a list of queries, one per line)
    @uploadOption=params[:uploadFile]
    @uf_mode = params[:uf_format] # valid: simple, xml
        
    # get the query from the params:
    @query_str = params[:query_str]

    
    if @outOp != 'trec' and (@query_str.nil? or @query_str.empty? or @query_str.strip.empty?)
      flash[:notice] = "Try entering a search query!"
      render :action => "index"
      return
    end
    
    case @outOp
    when 'trec'
      # figure out a topic number and run name:
      run_name = params[:topicSetName]
      case @uploadOption
      when 'singleQ' # use @query_str
        topic_number = params[:topicNo]
        @results, @mod_list, @syn_list = run_query(@query_str, parse_config_options)
        out = gen_trec(@results, topic_number, run_name)
      when 'uplF' # get queries from the uploaded file
        # TODO: error handling here- what if user didn't uplaod a query file?
        
        if @uf_mode == 'xml'
          queries = extract_topics_from_xml(params['file'].readlines.join)
        else
          queries = params['file'].readlines.collect { |line| line.strip }
        end
        out = ''
        queries.each_index do |i| 
          queryNumber = i + 1
          temp_results, mod, syn, qtokens, full_query = run_query(queries[i], parse_config_options)
          out << gen_trec(temp_results, queryNumber, run_name)
        end
      end
      render :text => out
    else # standard mode, just render the template
      @results, @mod_list, @syn_list, @q_tokens, @full_query = run_query(@query_str, parse_config_options)
      
      render :action => "search"
    end
        
  end
  
  private
  def run_query(q, parse_opts)    

    #return Record.find_by_caption(q)    

    qp = QueryParser.new
    
    # for now: hard-code column to 'caption'
    parse_opts[:column_to_use] = 'caption'
    
    full_query, modalities, synonyms, query_tokens, q = qp.parse(q,parse_opts)
    Rails.logger.info("full_query: #{full_query}")
    Rails.logger.info("modalities are: #{modalities.join(', ')}")
    Rails.logger.info("synonyms are: #{synonyms.join(', ')}")
    initial_results = Record.find_by_sql(full_query)
    second_results = []
    
    if parse_opts[:reorder] == true and parse_opts[:limit_modality] == true
      # re-run, without limiting by modality, and append the other results to the end
      parse_opts[:limit_modality] = false
      new_q, new_mod, new_syn, new_q_tokens, q2 = qp.parse(q,parse_opts)
      second_results = Record.find_by_sql(new_q)
      
      init_id_hash = initial_results.inject({}) { |h,r| h[r.id] = r; h }
      
      second_results = second_results.select { |r| init_id_hash[r.id].nil? }
      
      
      
      Rails.logger.info("there are #{second_results.size} extra results!")
      
    end
    
    final_results = initial_results.concat(second_results)
    
    # should we do an emergency suggestion?
    if final_results.size == 0
      
      final_results = run_suggestion_query(query_tokens, parse_opts[:column_to_use])
      
    end
    
    return final_results, modalities, synonyms, query_tokens, full_query
    
  end
  
  def gen_trec(results, topic_number, run_name)
    to_return = []
    
    results.each_index do  |r|
      rank = r + 1
      this_image = results[r]
      score = (1/rank.to_f).to_f # can also use score from search engine, if available
      # TODO: Document what the different columns here mean- for example, why do we have a hard-coded "1" in the second col?
      to_return << "#{topic_number}\t 1 \t #{this_image.image_local_name.split('.')[0]} \t #{rank}\t #{score}\t #{run_name}\n"
    end
    
    return to_return.join()
    
  end
  
  # ignores type (visual, semantic, etc.) and id- assumes that they are in order.
  def extract_topics_from_xml(xmlstr)
    
    x = Nokogiri::XML(xmlstr)
    
    return (x / "/Topics/topic/EN_DESCRIPTION").collect { |x| x.text }
    
  end
  
  def run_suggestion_query(q_tokens, col_to_use, threshold = nil) 
    
    # pick the longest token:
    longest_token = q_tokens.sort { |a,b| b.length <=> a.length }.first
    
    # turn it into a lexeme:
    raw = ActiveRecord::Base.connection.select_value("select to_tsvector('english','#{longest_token}')")
    lex = raw.split(':').first.gsub("'",'')
    
    unless threshold
      if lex.size <= 4
        threshold = 1
      else
        # Longer words should have more tolerance
        threshold = lex.size/3
      end
    end


    distances = []
    SUGGESTION_CORPUS.each_index do |i|

      candidate = SUGGESTION_CORPUS[i]

      length_diff = (lex.length - candidate.length).abs
      next unless length_diff <= 5

  
      this_dist = lev_distance(lex,candidate)


      next unless this_dist <= threshold

      distances << {:str => candidate, :dist => this_dist }

    end;
    sorted_distances = distances.sort { |a,b| a[:dist] <=> b[:dist] };

    sugg = sorted_distances.first[:str]
    
    # build the query:
    q = "select r.*, ts_rank_cd(to_tsvector(#{col_to_use}), to_tsquery('english','#{sugg}')) as rank from records r where to_tsvector('english',#{col_to_use}) @@ to_tsquery('english','#{sugg}')"
    return Record.find_by_sql(q)
    
  end
  
  # stolen from Text gem; weird encoding problem is why I re-implemented it
  def lev_distance(s1, s2)
    s = s1
    t = s2
    n = s.length
    m = t.length
    return m if (0 == n)
    return n if (0 == m)

    d = (0..m).to_a
    x = nil

    (0...n).each do |i|
      e = i+1
      (0...m).each do |j|
        cost = (s[i] == t[j]) ? 0 : 1
        x = [
          d[j+1] + 1, # insertion
          e + 1,      # deletion
          d[j] + cost # substitution
        ].min
        d[j] = e
        e = x
      end
      d[m] = x
    end

    return x
    
    
  end
  
end
