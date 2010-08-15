mods = open('imageclef2010_orig_mod.txt').readlines

count = 0

mods.each do |m|
  
  puts count if count % 500 == 0
  count = count + 1
  
  parts = m.split(',').collect { |p| p.strip }
  next unless parts[1].present?
  
  r = Record.find_by_figure_id(parts[0])
  next unless r.present?
  next if r.jaykc_modality.present?
  r.jaykc_modality = parts[1]
  r.save
  
end

puts "there were #{count} images with observed modalities."