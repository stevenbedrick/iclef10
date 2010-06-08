class GhettoStemmer
  
  # returns an array of stemmed tokens
  def self.stemline(some_line, append_star=true)
    
    tokens = some_line.split(/\s/)
    tokens.collect! { |t| GhettoStemmer.stemword(t, append_star)}
    
    return tokens
    
  end
  
  def self.stemword(some_word, append_star=true)
    
    stemmed = some_word
  
    # rule 1: if the word ends in "phies" or "phy", end with "ph*"
    r = /(phies$)|(phy$)/
      
    # rule 2: if the word ends in "s", lose it and replace with "*"
    # but not if it ends in "-us" or "-is"
    s = /[^ui]s$/
    
    if some_word.strip =~ r
      if append_star
        stemmed = some_word.strip.gsub(r,"ph*")
      else
        stemmed = some_word.strip.gsub(r,"ph")
      end
    elsif some_word.strip =~ s
      if append_star
        stemmed = some_word.strip.gsub(/s$/,'*')
      else
        stemmed = some_word.strip.gsub(/s$/,'')
      end
    end
    
    return stemmed
    
  end
  
end