class SearchController < ApplicationController
  
  def index
    
  end
  
  def search

    # get the query from the params:
    @query_str = params[:query_str]

    if @query_str.nil? or @query_str.empty? or @query_str.strip.empty?
      flash[:notice] = "Try entering a search query!"
      render :action => "index"
      return
    end
    
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
    @umlsSynonym=(params['umlsSynonym']) # use UMLS query expansion?
    @columnOp=(params['columnOp']) # which caption column to use?
    @titleOp=(params['titleOp']) # include titles, or just captions?
    @stem_and_star = params[:stem_and_star] # stem and wildcard query terms?
    @unique = params[:unique_term] # only include unique terms after stemming/expansion?
    
    # we're done getting raw parameters from query params, now let's do useful stuff with them:
    
    # set up configuration hash for query parser:
    parse_config_options = {
      :parse_mode => :simple_or,
      :limit_modality => false,
      :umls_synonym_expansion => false,
      :column_to_use => 'caption',
      :stem_and_star => @stem_and_star,
      :unique_terms => @unique,
      :add_title => false
    }
     
    # what col to use?
    case @columnOp
      when 'a'
        parse_config_options[:column_to_use] = 'caption'
      else 'b'
        parse_config_options[:column_to_use] = 'parsed_caption'
    end # ends case @columnOp
    
    ##### output mode:
    ##### we can output results as either standard web view or as a TREC-formatted run file
    # possible values: 'trec' (trec-formatted output), 'std' (standard interactive output)
    @outOp=(params['outOp'])
    
    ##### when we're in TREC mode, users can enter a single query or a file full of a batch of queries
    # possible values: 'singleQ' (use @query_str), 'uplF' (look for params[:file] for a list of queries, one per line)
    @uploadOption=params[:uploadFile]
    
    case @outOp
    when 'trec'
      # figure out a topic number and run name:
      run_name = params[:topicSetName]
      case @uploadOption
      when 'singleQ' # use @query_str
        topic_number = params[:topicNo]
        @results = run_query(@query_str, parse_config_options)
        out = gen_trec(@results, topic_number, run_name)
      when 'uplF' # get queries from the uploaded file
        # TODO: error handling here- what if user didn't uplaod a query file?
        queries = params['file'].readlines.collect { |line| line.strip }
        out = ''
        queries.each_index do |i| 
          queryNumber = i + 1
          temp_results = run_query(queries[i], parse_config_options)
          out << gen_trec(temp_results, topic_number, run_name)
        end
      end
      render :text => out
    else # standard mode, just render the template
      @results = run_query(@query_str, parse_config_options)
      render :action => "search"
    end
        
  end
  
  private
  def run_query(q, parse_opts)    
    # for now:
    return Record.find_by_caption(q)    
  end
  
  def gen_trec(results, topic_number, run_name, include_header = true)
    to_return = []
    if include_header
      to_return << "#{topic_number} \t 1 \t 1234 \t 1 \t 0 \t#{run_name}\n"
    end
    
    results.each_index do  |r|
      rank = r + 1
      this_image = results[r]
      score = (1/rank.to_f).to_f # can also use score from search engine, if available
      # TODO: Document what the different columns here mean- for example, why do we have a hard-coded "1" in the second col?
      to_return << "#{topic_number}\t 1 \t #{this_image.image_local_name.split('.')[0]} \t #{rank}\t #{score}\t #{run_name}\n"
    end
    
    return to_return.join()
    
  end
  
end
