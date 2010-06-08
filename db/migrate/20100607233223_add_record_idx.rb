class AddRecordIdx < ActiveRecord::Migration
  def self.up
    add_index :records, :figure_id
    add_index :records, :pmid
    execute "CREATE INDEX record_caption_idx ON records USING gin(to_tsvector('english', caption));"
    execute "CREATE INDEX record_title_idx ON records USING gin(to_tsvector('english', title));"
    execute "CREATE INDEX record_full_caption_idx ON records USING gin(to_tsvector('english', full_caption));"
    execute "CREATE INDEX record_parsed_caption_idx ON records USING gin(to_tsvector('english', parsed_caption));"
    
  end

  def self.down
  end
end
