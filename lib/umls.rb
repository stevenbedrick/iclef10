#!/usr/bin/env ruby
#
#  Created by Steven Bedrick on 2007-10-06.
#  
#  Provides a simple library to access my web-based UMLS server.
#
#  Does not necessarily require UMLS knowledge on the user's part- 
#  there are methods that do not involve specifying CUIs, etc.
#

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'cgi'
require 'builder'
require 'rexml/document'



include REXML

class UMLSClient
  
#  @server_base_url = 'http://localhost:3334'
#  @server_base_url = 'http://localhost:3001'
  @server_base_url = 'http://ir.ohsu.edu'
  @url_prefix = 'umls'
  @http_headers = {'Accept' => 'text/xml'}

  def self.server_base_url
    @server_base_url
  end
  
  def self.server_base_url=(some_url)
    @server_base_url = some_url
  end

  def self.url_prefix
    @url_prefix
  end
  
  def self.url_prefix=(some_prefix)
    @url_prefix = some_prefix
  end
  
  # Returns an array of hashes- each hash's key is a cui, each hash's value is the string.
  #
  # The array is in the same order that the search engine returned the results.
  #
  # By default, limits to 100 cuis returned. 
  #
  # Pass in "nil" as a limit to retrieve *all* results- note that this could take a while for certain 
  # queries (i.e., 'heart', or 'cancer')...
  #
  # Also note that due to limitations of the UMLS, this won't work for all languages- since it
  # depends on finding preferred terms for concepts, and not all concepts have preferred terms in all languages,
  # it might be best to stick with English or possibly Spanish, and at least fall back on English if
  # there are no results or something like that.
  def self.find_concepts(query, options={})
    
    language='ENG', limit=100
    
    if options[:language].nil?
      options[:language] = 'ENG'
    end
    
    if options[:limit].nil?
      options[:limit] = 100
    end
    
#    start_time = Time.now.to_f
    
    # url prefix is taken care of in submit_query
    path = '/term/find_concepts_by_query'
    arg_hash = {}
    arg_hash['search_term'] = query

    arg_hash['language'] = options[:language]
    
    if (not options[:limit] == :all) and options[:limit].is_a? Fixnum
      arg_hash['limit'] = limit.to_s
    end

#    puts 'about to submit query...' + Time.now.to_f.to_s
    
    doc = UMLSClient.submit_query(path,arg_hash)
    
#    puts 'got doc, about to traverse...' + Time.now.to_f.to_s
    
    concept_arr = (doc / '/response/concept').collect { |c|
      
      cui = (c / 'cui').inner_text

      str = (c / 'str').inner_text
      #puts "processing #{cui}: #{str}"      
      {cui => str}
      
    }
    
#    puts 'done!...' + Time.now.to_f.to_s
    
#    puts 'elapsed time: ' + (Time.now.to_f - start_time).to_s
    
    return concept_arr
 
  end

  # can accept an array of CUIs
  def self.find_semantic_types_for_cui(cui)
    
    path = '/term/semantic_types'
    arg_hash = {}
    if cui.is_a? Array
      arg_hash['cui'] = cui.join(',')
    else
      arg_hash['cui'] = cui
    end
    
    doc = UMLSClient.submit_query(path, arg_hash)
    
    semantic_type_arr = (doc / '/response/semantic_type').collect { |st| 
    
      cui = (st / 'cui').inner_text
      tui = (st / 'tui').inner_text
      sem_type = (st / 'sty').inner_text
      
      {:cui => cui, :tui => tui, :semantic_type => sem_type}
      
    }
    
    return semantic_type_arr

  end

  def self.find_semantic_types_by_query(query, options={})
    
    path = '/term/semantic_types_by_query'
    arg_hash = {}
    
    arg_hash['query'] = query
    
    doc = UMLSClient.submit_query(path, arg_hash)

    semantic_type_arr = (doc / '/response/semantic_type').collect { |st| 
    
      cui = (st / 'cui').inner_text
      tui = (st / 'tui').inner_text
      sem_type = (st / 'sty').inner_text
      stn = (st / 'stn').inner_text
      
      {:cui => cui, :tui => tui, :semantic_type => sem_type, :stn => stn}
      
    }
    
    return semantic_type_arr
    
    
  end

# "Proper"- but broken- way to do find_semantic_types_by_query.
# this approach results in "congenital malformation" ("Arachnodactyly") being returned for "finger" rather than "body part"!
#
#  language='ENG', limit=100
#  
#  if options[:language].nil?
#    options[:language] = 'ENG'
#  end
#  
#  if options[:limit].nil?
#    options[:limit] = 100
#  end
#  
#  cui_array = self.find_concepts(query, options)
#  
#  cui_list = cui_array.collect { |c|
#    c.keys[0]
#  }
#  
#  return self.find_semantic_types_for_cui(cui_list)
#

  # this method will require some UMLS knowledge to deal with, I'm afraid...
  def self.concept_details_by_cui(cui)
    
    path =  '/term/cui/' + cui
    arg_hash = {}
    
    doc = UMLSClient.submit_query(path,arg_hash)
    
    concept_hash = {}
    
    # get the cui...
    concept_hash[:cui] = (doc / '/response/cui').inner_text
    
    # now the preferrred term...
    pref_term_nodes = doc / '/response/preferred_term'
    
    pref_term_hash = {}
    
    pref_term_hash[:lui] = (pref_term_nodes / 'lui').inner_text
    pref_term_hash[:str] = (pref_term_nodes / 'str').inner_text
    
    concept_hash[:preferred_term] = pref_term_hash
    
    # now for the definitions
    def_nodes = doc / '/response/definitions'
    
    if def_nodes.size > 0
    
      def_array = []
      
      (def_nodes / 'definition').each { |d|
      
        str = (d / 'str').inner_text
        source = (d / 'source').inner_text
        
        def_array << {:str => str, :source => source}
        
      }
      
      concept_hash[:definitions] = def_array
      
    end 
    
    # okay... after definitions, it's time for the hard stuff:
    
    term_nodes = (doc / '/response/terms/term')
    
    term_array = []
    
    fields = %w[lui sui aui lat stt str sab tty term_type scui].collect { |s| s.to_sym }
    
    term_nodes.each {|t|
    
      this_term = {}
      
      fields.each { |f|
        this_term[f] = (t / f.to_s ).inner_text
      }      
      
      term_array << this_term
    }
    
    concept_hash[:terms] = term_array
    
    return [concept_hash,doc]
    
  end
  
  def self.synonyms_by_cui(cui)
    
    path =  '/term/synonyms'
    
    arg_hash = {'cui' => cui}
    
    doc = UMLSClient.submit_query(path,arg_hash)
    
    # first- are there any synonyms?
    if (doc / '/response').inner_text.strip.empty?
      return nil
    end
    
    # there should only be one cui:
    
    concept_node = doc / 'response/concept'
    
    cui_syn_hash = UMLSClient.parse_single_concept_node(concept_node)
    
    return [cui_syn_hash,doc]
     
  end
  
  # in this case, limit refers to the max number of CUIs to consider
  # find_synonyms will return an array of hashes, one hash per CUI returned
  # by query, in the order in which the search system gave them to us.
  def self.find_synonyms(query, options = {})
    
    if query.nil? or query.empty?
      return []
    end
    
    # default options:
    if options[:language].nil?
      options[:language] = 'ENG'
    end
    
    if options[:limit].nil?
      options[:limit] = 100
    end
    
    if options[:include_pref_term_in_sym_list].nil?
      options[:include_pref_term_in_sym_list] = true
    end

    path =  '/term/synonyms'
    
    arg_hash = {'search_term' => query, 'language' => options[:language], 
                'limit' => options[:limit].to_s, 'include_self' => options[:include_pref_term_in_sym_list].to_s}
    
    if options[:language] == :all
      arg_hash['language'] = 'all'
    end

    doc = UMLSClient.submit_query(path,arg_hash)
    
    concept_node_list = doc / '/response/concept'
    
    to_return = []
    concept_node_list.each { |concept_node|
    
      temp = UMLSClient.parse_single_concept_node(concept_node)
            
      to_return << temp
      
    }
    
    return to_return
    
  end
  
  private
  
    # submitQuery takes a path and a hash of arguments,
  # urlencodes the arguments, builds a url out of @server_base_url,
  # the path, and the arguments; does an HTTP get on that URL,
  # and turns the response into an hpricot document.
  
  def self.submit_query(path, arg_hash)
  
    # path must start with a slash:
    if not path =~ /^\//
      # raise some sort of exception, eventually
      return nil
    end
    
    # let's get some arguments together:
    if arg_hash.nil? or arg_hash.empty?
      arg_str = ''
    else      
      arg_arr = arg_hash.collect { |arg,val|      
        escaped_arg = CGI.escape(arg)
        escaped_val = CGI.escape(val)
        "#{escaped_arg}=#{escaped_val}"      
      }      
      arg_str = arg_arr.join('&')      
    end
    
    url = @server_base_url + '/' + @url_prefix + path + "?" + arg_str
    
    
#    puts url
    # okay, we've got the url- now let's run it:
    
#    puts 'about to submit...' + Time.now.to_f.to_s
    response = open(url, @http_headers)
#    puts "got response...: #{response.class}" + Time.now.to_f.to_s


    to_return = Hpricot.XML(response)
    
#    puts 'got Hpricot...' + Time.now.to_f.to_s
    
    return to_return
        
  end

  
  def self.parse_single_concept_node(concept_node)

    cui_syn_hash = {}
        
    cui_syn_hash[:cui] = (concept_node / 'cui').inner_text
    
    # now get the preferred term:
    pref_term_node = concept_node / 'preferred_term'
    pref_term_lui = (pref_term_node / 'lui').inner_text
    pref_term_str = (pref_term_node / 'str').inner_text
    pref_term_sab = (pref_term_node / 'sab').inner_text
    pref_term_lang = (pref_term_node / 'language').inner_text
    
    cui_syn_hash[:preferred_term] = {:lui => pref_term_lui, :str => pref_term_str, :sab => pref_term_sab, :language => pref_term_lang}
    
    # now the synonyms:
    syn_array = []
        
    syn_nodes = concept_node / 'synonyms/synonym'
    
    syn_nodes.each { |s|
    
      lui = (s / 'lui').inner_text
      str = (s / 'str').inner_text
      sab = (s / 'sab').inner_text
      lang = (s / 'language').inner_text
      
      syn_array << {:lui => lui, :str => str, :sab => sab, :language => lang}
      
    }
    
    cui_syn_hash[:synonyms] = syn_array
    
    return cui_syn_hash
    
  end
  
end