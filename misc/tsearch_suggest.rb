require 'rubygems'
require 'text'

@corpus = open('misc/fixed_tsvec.out').readlines.collect { |l| l.split('|')[0].strip };

def suggest(w,threshold = nil)
  
  
  # turn word into lexeme:
  raw = ActiveRecord::Base.connection.select_value("select to_tsvector('english','#{w}')")
  lex = raw.split(':').first.gsub("'",'')
  
  unless threshold
    if lex.size <= 4
      threshold = 1
    else
      # Longer words should have more tolerance
      threshold = lex.size/3
    end
  end
  
  
  lengths = []
  @corpus.each_index do |i|
    
    candidate = @corpus[i]

    length_diff = (lex.length - candidate.length).abs
    next unless length_diff <= 5
    
    this_dist = Text::Levenshtein.distance(lex,candidate)
    
    next unless this_dist <= threshold
    
    lengths << {:str => candidate, :dist => this_dist }
    
  end;
  sorted_lengths = lengths.sort { |a,b| a[:dist] <=> b[:dist] };
  
  return sorted_lengths.first[:str]

end

word = "eluphant"

puts "orig: #{word}"
puts "suggest: #{suggest(word)}"