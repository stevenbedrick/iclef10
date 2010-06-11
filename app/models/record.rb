require 'tempfile'

class Record < ActiveRecord::Base

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
  
  def metamap
    
    mm_cmd = "/home/bedrick/mm/public_mm/bin/metamap09 -% "
    
    # write caption to temp out file:
    tmpfile = Tempfile.new(self.id) # use this record id as base- should help avoid collisions
    file = File.new(tmpfile.path,'w')
    file.puts self.caption
    file.close
    
    tmp_outfile = Tempfile.new(self.id.to_s + '_out')
    
    full_cmd = mm_cmd + tmpfile.path + ' ' + tmp_outfile.path
    `#{full_cmd}`
    
    # read the mm output:
    mm = mm_output_from_str(File.open(tmp_outfile.path).readlines.join)
    
    return mm
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
              t << types[st.text]
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
  
end
