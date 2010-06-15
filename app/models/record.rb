require 'ruby-debug'

class Record < ActiveRecord::Base

  belongs_to :article, :class_name => "Article", :foreign_key => "pmid"
  has_and_belongs_to_many :mesh_terms

  def Record.find_by_caption(q)
    
    query = "select * from records where to_tsvector('english',caption) @@ plainto_tsquery('english', ? )"
    return Record.find_by_sql([query, q])
    
  end
  
  def Record.find_by_title(q)
    
    query = "select * from records where to_tsvector('english',title) @@ plainto_tsquery('english', ? )"
    return Record.find_by_sql([query, q])
    
  end
  
  def image_full_path
    "http://skynet.ohsu.edu/iclef10_data/#{self.figure_id}.jpg"
  end
  
  def metamap(only_msh = false)
    
    mm_cmd = "/home/bedrick/mm/public_mm/bin/metamap09 -% noformat "
    if only_msh
      mm_cmd << "-R MSH "
    end
    
    # write caption to temp out file:
    tmpfile = Tempfile.new(self.id) # use this record id as base- should help avoid collisions
    file = File.new(tmpfile.path,'w')
    file.puts self.caption
    file.close
    
    tmp_outfile = Tempfile.new(self.id.to_s + '_out')
    
    full_cmd = mm_cmd + tmpfile.path + ' ' + tmp_outfile.path
    #puts full_cmd
    `#{full_cmd}`
    
    # read the mm output:
    raw_output = File.open(tmp_outfile.path).readlines.join
    mm = mm_output_from_str(raw_output)
    
    # clean up files:
    File.unlink(tmpfile.path)
    File.unlink(tmp_outfile.path)
    
    return mm
  end

  def load
    
    mappings = self.metamap(true) # only metamap to MeSH
    #puts mappings
    # mm returns semantic type abbreviations. If a mapping isn't in this whitelist, we don't care about it:
    abbrev_whitelist = [
      'dsyn',
      'neop',
      'neop',
      'patf',
      'cgab',
      'anab',
      'bpoc',
      'blor',
      'acab',
      'diap',
      'cell',
      'spco',
      'inpo'
    ]
    
    chosen = []

    mappings.each do |m|
      mapped_concepts = m[:mappings]
      mapped_concepts.each do |mc|
        valid = false
        mc[:semantic_types].each do |st|
          valid = true if abbrev_whitelist.include? st
        end
        chosen << mc[:cui] if valid
      end
    end
    
    # use http://skynet.ohsu.edu/meshtrans/mesh_mh_by_cui to map each cui to its mesh major heading
    main_headings = resolve_main_headings(chosen)

    # store in database somewhere...
    main_headings.each do |mh|
      m = MeshTerm.find_or_create_by_term(mh[:str])
      self.mesh_terms << m
    end
    
    self.save
    
    if chosen.size > 0
#      Debugger.start
#      debugger
    end
    
    return {:orig => chosen, :mh => main_headings}
    
  end
  
  private
  def mm_output_from_str(xml)
    to_return = []

    n = Nokogiri::XML(xml)

    mapped_phrases = n / '/MMOlist/MMO/Utterances/Utterance/Phrases/Phrase[Mappings[@Count!="0"]]'
    mapped_phrases.each do |phrase|

      this_phrase = {}
      this_phrase[:text] = (phrase / 'PText').text

      offset_start = (phrase / 'PStartPos').text
      offset_len = (phrase / 'PSpanLen').text

      this_phrase[:offsets] = [offset_start, offset_len]

      mappings = phrase / 'Mappings/Mapping'

      map_arr = []

      mappings.each do |m|

        candidates = m / 'Candidates/Candidate'
        candidates.each do |c|
          this_candidate = {}
          this_candidate[:cui] = (c / 'UMLSCUI').text
          this_candidate[:concept_name] = (c / 'UMLSConcept').text
          this_candidate[:preferred_name] = (c / 'UMLSPreferred').text

          sem_types = (c / 'STs/ST')
          t = []
          if sem_types.size > 0
            sem_types.each do |st|
              t << st.text
            end
          end

          this_candidate[:semantic_types] = t

          map_arr << this_candidate
        end
      end # ends each mapping

      this_phrase[:mappings] = map_arr
      to_return << this_phrase
    end # ends phrases
    return to_return
  end
  
  def resolve_main_headings(cui_list)
    
    # use http://skynet.ohsu.edu/meshtrans/mesh_mh_by_cui to map each cui to its mesh major heading
    mh_url = "http://skynet.ohsu.edu/meshtrans/mesh_mh_by_cui"
    hydra = Typhoeus::Hydra.new
    
    main_headings = []
    
    cui_list.uniq.each do |c|
      # set up a request:
      this_req = Typhoeus::Request.new(mh_url, :method => :get, :params => {:cui => c})
      this_req.on_complete do |resp|
        begin
          r = JSON.parse(resp.body)
          if r['str']
            main_headings << {:cui => c, :str => r['str']}
          end
        rescue # json parsing error of some sort- shouldn't happen...
          next
        end
      end
      hydra.queue(this_req)
    end
    
    hydra.run
    
#    main_headings.each do |mh|
#      puts "#{mh[:cui]}\t\t#{mh[:str]}"
#    end

    return main_headings
    
  end
  
end
