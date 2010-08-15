count = 0

Record.find(:all).each do |r|
  
  puts count if count  % 500 == 0
  count += 1
  
  caption_modalities = ModTagger.modExtractor(r.caption)
  title_modalities = ModTagger.modExtractor(r.title)
  both_modalities = ModTagger.modExtractor(r.caption + ' ' + r.title)
  
#  puts "caption: #{caption_modalities.join(', ')}"
#  puts "title: #{title_modalities.join(', ')}"
#  puts "both: #{both_modalities.join(', ')}"
#  puts
  
  r.caption_modality = caption_modalities.join(', ')
  r.title_modality = title_modalities.join(', ')
  r.caption_title_modality = both_modalities.join(', ')
  r.save
  
end

puts "done!"