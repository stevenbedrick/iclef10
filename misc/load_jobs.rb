ids = ActiveRecord::Base.connection.select_values('select id from records')

count = 0

ids.each do |i|
  puts count if count % 1000 == 0
  count += 1
  r = Record.find(i)
  r.delay.load
  
end