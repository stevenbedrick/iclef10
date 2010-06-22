q = QueryParser.new

count = 0

rec = Record.find(:all, :include => [:mesh_terms, {:article => {:assigned_mesh_terms => :mesh_term}}])

#rec = Record.find(:all).first(10)

total = rec.size



rec.each do |r|
  
  puts "#{count}/#{total} (#{(count.to_f / total.to_f) * 100 }% )" if count % 1 == 0
  count += 1
  # article mh
  
  if r.article.present? and r.article.assigned_mesh_terms.present?
    
    terms_joined = r.article.assigned_mesh_terms.map(&:term).join(' ')
    stop_removed = q.remove_stop_words(terms_joined)
    r.pubmed_mh = stop_removed
#    puts terms_joined
#    puts "\tStop-words Removed: #{stop_removed}"
    if r.article.major_topics.present?
      major = r.article.major_topics.map(&:term).join(' ')
      major_stop = q.remove_stop_words(major)
      r.pubmed_mh_major = major_stop
#      puts "\tmajor: #{major}"
#      puts "\t\tStop-words Removed: #{major_stop}"
    end
    
  end

  # mm mh
  if r.mesh_terms.present?
    
    terms_joined = r.mesh_terms.map(&:term).join(' ')
    mm_no_stop = q.remove_stop_words(terms_joined)
#    puts "from metamap: #{terms_joined}"
#    puts "\tno stop words: #{mm_no_stop}"
    r.metamap_mh = mm_no_stop
    
  end
  
  r.save
  
#  puts
  
end