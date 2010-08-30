require 'ferret'

# this class's job is to put together an SQL query that uses PostgreSQL's tsearch syntax.

class QueryParser
  @parse_modes = [:exact_match, :simple_or, :simple_and, :fuzzy_or, :custom]

  def parse(query, options={})

    if query.nil? or query.strip.empty?
      return nil
    end

    config_options = {
      :parse_mode => :simple_or,
      :limit_modality => false,
      :remove_mod_tokens => true,
      :mod_column => 'caption_modality',
      :umls_synonym_expansion => false,
      :column_to_use => 'parsed_caption',
      :stem_and_star => false,
      :unique_terms => false,
      :add_title => false,
      :pubmed_mh => false,
      :pubmed_mh_major => false,
      :metamap_mh => false
    }

    config_options.merge!(options)

    modalities = []
    synonyms = []
    q_tokens = []

    Rails.logger.info "config_options[:parse_mode]: #{config_options[:parse_mode]}"

    # q will end up a hash with two items: :tokens and :concat
    case config_options[:parse_mode]

      when :exact_match
        q = exact_match(query)
      when :simple_or
        q = simple_or(query)
      when :simple_and
        q = simple_and(query)
# => Postgres doesn't support fuzzy searching...
#      when :fuzzy_or
#        q = fuzzy_or(query)
      when :custom
        q, modalities, synonyms, q_tokens = custom(query, config_options)
# => sdb_custom_parser is not working at the moment
#      when :sdb
#        q, modalities, synonyms = sdb_custom_parser(query, config_options)
      else
        q = query
    end
    
    
#    joined_query = q[:tokens].collect { |t| sql_escape(t) }.join(' ' + q[:concat] + ' ')

    
    # example: to_tsvector('english',title) @@ to_tsquery('english', 'monkeys & liver' )
    
    # figure out cols:
    col = config_options[:column_to_use]
    if config_options[:add_title]
      col = col + " || ' ' || title"
    end
    
    if config_options[:pubmed_mh] 
      if config_options[:pubmed_mh_major]
        col = col + " ||  ' ' || pubmed_mh_major"
      else
        col = col + " ||  ' ' || pubmed_mh"
      end
    end
    
    if config_options[:metamap_mh]
      col = col + " ||  ' ' || metamap_mh"
    end
    

    
    query_str = "to_tsvector('english',#{col}) @@ to_tsquery('english','#{q}')"
    rank_str = "ts_rank_cd(to_tsvector(#{col}), to_tsquery('#{q}'))"


    mod_limit = ''
    if config_options[:limit_modality] and not modalities.empty?

      adj_mod = modalities.select { |m| not m.strip.empty? }.join(' | ')
      
      # which cols?
      mod_col = case config_options[:mod_column]  
      when :title
        'title_modality'
      when :caption_title
        "caption_modality || ' ' || title_modality"
      when :jaykc
        'jaykc_modality'
      when :all
        "caption_modality || ' ' || title_modality || ' ' || jaykc_modality"
      else
        "caption_modality"
      end
      
      mod_limit = "and to_tsvector('english',#{mod_col}) @@ to_tsquery('english','#{adj_mod}') "      
    end
    
    full_query = "select r.*, #{rank_str} as rank from records r where #{query_str} "
    if not mod_limit.blank?
      full_query << mod_limit
    end
    full_query << " order by rank desc"
    
        
#    full_query = query_parts.join(' ')
    
    return full_query, modalities, synonyms, q_tokens, q

  end

  def exact_match(query) 

    return query

  end

  def simple_or(query)
    
    return query.split(/ /).join(' | ')

  end

  def simple_and(query)

    return query.split(/ /).join(' & ')

  end

#  # currently unsupported...
#  def fuzzy_or(query)
#
#    q = query.split(/ /).join('~ OR ')
#    q << '~'
#
#    return q
#
#  end


######## NOTE: sdb_custom_parser does not work. Do not use it...
  def sdb_custom_parser(query, options)

    #first, remove stop words:
    raw_tokens = remove_stop_words(query, false).uniq

    # next, get part of speech tags for each token:
    tagged_tokens = TAGGER.get_tag_structure(raw_tokens)

    # modality extraction:
    modalities = []
    modality_removed_tokens = []
    raw_tokens.each do |t|
      if ModTagger.modExtractor(t).size == 0 # if t is not a modality token:
        modality_removed_tokens << t
      else # t must be a modality token:
        modalities << ModTagger.modExtractor(t)
      end
    end

    # kill duplicates:
    modalities.uniq!

    # pos tag the modality-removed tokens:
    mod_removed_tokens_pos = TAGGER.get_tag_structure(modality_removed_tokens)

    # at this point, modalities should be an array of modalities (duh), and modality_removed_tokens should be
    # an array of the tokens that were not modality terms. Note that we've still got raw_tokens lying around.

    # next, do some n-gram-based synonym extraction:
    # start with trigrams, then go to bigrams- we'll just take the first one that we find:

    synonyms = []

    3.downto(1) do |n|
#      puts
#      puts "n is: #{n}"
      n_grams = n_gram_extract(modality_removed_tokens, n)

#      puts "#{n_grams.size} #{n}-grams found."

      n_grams.each_index do |i|
        ng = n_grams[i]
#        puts "#{n}-gram #{i}: #{ng.join(', ')}"
        pos_offset = i
#        puts "tags for this ng: "
        ng_tags = []
        ng.each_index do |j|
          ng_tags << mod_removed_tokens_pos[j + pos_offset]
#          puts "token: #{mod_removed_tokens_pos[j + pos_offset][:token]}"
#          puts "tag: #{mod_removed_tokens_pos[j + pos_offset][:tag]}"
        end

        # if all adjectives, no point in doing synonyms:
        t = ng_tags.collect { |h| h[:tag] }.uniq

        if t.size == 1 and t[0] == 'JJ'
          puts "n is #{n}, tags for \"#{ng.join(' ')}\" are all adjectives, not bothering..."
          next
        end

        stemmed = GhettoStemmer.stemline(ng.join(' '), false)

        puts "n is #{n}, about to find synonyms for \"#{ng.join(' ')}\" (stemmed: \"#{stemmed.join(', ')}\")"

        syn = UmlsUtilities.findSynonymsSdb(stemmed.join(' '))

        if not syn.empty?
          puts "found: #{syn}"
          synonyms << syn
#          break
        end

        puts "---------\n"
      end

 #     break unless synonyms.nil?

    end

    synonyms.flatten!

    # now, tokenize and stop-word remove our synonyms:
    raw_syn_tokens = []
    uniq_syn_tokens = []
    if not synonyms.nil?
      raw_syn_tokens = synonyms.collect { |s| remove_stop_words(s, false) }
      uniq_syn_tokens = raw_syn_tokens.flatten.uniq
    end

#    Debugger.start
#    debugger

    return modality_removed_tokens.join(' '), modalities.flatten, [uniq_syn_tokens.join(' ')]

  end

  def custom(query, options)

    ###########modality check#############
    temp_query = ''
    modalities = []
    modTerms = []

    stop_word_removed_tokens = remove_stop_words(query.downcase, false) # passing in false to get back an array of tokens
    
    Rails.logger.info('stop_word_removed_tokens: ' + stop_word_removed_tokens.join(', '))
    
    query_tokens = []
    

    if options[:limit_modality] or options[:remove_mod_tokens]
      # remove modality tokens from query- we'll handle those separately
      stop_word_removed_tokens.each do |thisTerm|
        if  ModTagger.modExtractor(thisTerm).size == 0  ## this term is not a modality
          query_tokens << thisTerm
        else
          modalities << ModTagger.modExtractor(thisTerm)
          modTerms << thisTerm          
        end
      end
    else
      query_tokens = stop_word_removed_tokens
    end	

    # temp_query should now be modality and stop-word free, but just in case that got rid of everything:
    if query_tokens.empty?
      query_tokens = modTerms
    end

    Rails.logger.info('query_tokens: ' + query_tokens.join(', '))

    modalities = modalities.flatten.uniq

    final_sym_list = []

    # do we want to worry about synonyms?
    if options[:umls_synonym_expansion]
      
      synonyms = UmlsUtilities.findSynonymsExtended(query_tokens.join(' '))
      synonyms = [synonyms] unless synonyms.is_a? Array
      
      if synonyms
        # get rid of parentheses:
        cleaned_synonyms = synonyms.collect { |s| s.gsub(/\(|\)/,'')}
        final_sym_list = cleaned_synonyms.collect { |s| remove_stop_words(s) }
#        query_tokens = query_tokens + cleaned_synonyms.collect { |s| remove_stop_words(s) }
      end
    else
      synonyms = []
    end
    
    Rails.logger.info('final_sym_list: ' + final_sym_list.join(', '));
    
    if options[:uniq_terms]
      query_tokens = query_tokens.uniq
      final_sym_list = final_sym_list.uniq
      Rails.logger.info('in uniq_terms:')
      Rails.logger.info("\t" + 'query_tokens: ' + query_tokens.join(', '))
      Rails.logger.info("\t" + 'final_sym_list: ' + final_sym_list.join(', '));
    end
    
    # now we've got tokens, and, possibly, synonyms, and they've been uniqued if necessary. Stemming, anybody?
    # the way stemming/wildcard syntax works in tsearch is like so: photography -> photograph:*

    if options[:stem_and_star]
      query_tokens = query_tokens.collect { |part| GhettoStemmer.stemword(part, false) + ':*' } 
      final_sym_list = final_sym_list.collect { |s| s.collect { |t| GhettoStemmer.stemword(t, false) + ':*' } }
      Rails.logger.info('in stem_and_star:')
      Rails.logger.info("\t" + 'query_tokens: ' + query_tokens.join(', '))
      Rails.logger.info("\t" + 'final_sym_list: ' + final_sym_list.join(', '));

    end
    
    #recompose the query:
    
    orig_query = "(" + query_tokens.join(' & ') + ")"
    Rails.logger.info("orig_query: #{orig_query}")
    if final_sym_list.size > 0
      
      sym_query = "(" + final_sym_list.collect { |s| "("+ s.split.join(' & ') + ")"}.join(' | ') + ")"
    else
      sym_query = ""
    end
 
    temp_query = orig_query
    if not sym_query.blank?
      temp_query << " | " + sym_query
    end
    
#    temp_query = {:tokens => query_tokens, :concat => '|'}
    
    return temp_query, modalities, synonyms, query_tokens

  end # ends custom parsing

  def remove_stop_words(str,join=true)

    stop_words = Ferret::Analysis::ENGLISH_STOP_WORDS
    new_stop_words = ['including', 'show', 'me', 'image','images' ,'cases','containing', 'showing', 'with', 'one', 'more', 'several', 'entire','full-body', 'colored', 'all', 'modalities'] # added jkc
    new_stop_words << 'scan' # added sdb
    final_stop_words = stop_words + new_stop_words

    tk = Ferret::Analysis::StandardTokenizer.new(str.downcase)
    stTk = Ferret::Analysis::StopFilter.new(tk, final_stop_words)

    out = []

    while x = stTk.next
      out << x.text
    end

    if join
      return out.join(' ')
    else
      return out
    end

  end

  # returns an array of n-gram token arrays from tokens
  def n_gram_extract(tokens, n)

    to_return = []

    0.upto(tokens.length-1) do |i|

      if (i + n) <= tokens.length
        parts = []
        n.times do |j|
          parts << tokens[j+i]
        end
        to_return << parts
      end

    end    

    return to_return

  end

  private
  def sql_escape(str)
    return ActiveRecord::Base.connection.quote_string(str)
  end
  
end