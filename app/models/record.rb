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
  
end
