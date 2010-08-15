infile = open('tsvec.out')

outfile = open('fixed_tsvec.out','w')

infile.gets
infile.gets

while l = infile.gets
  
  parts = l.split('|').collect { |p| p.strip }
  
  next unless parts[0].length > 3
  next if parts[0] =~ /\W/ # any non-word char
  
  outfile.puts l
  
end

infile.close
outfile.close