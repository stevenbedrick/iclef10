class AddModalityIndex < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX title_modality_idx ON records USING gin(to_tsvector('english', title_modality));"
    execute "CREATE INDEX caption_modality_idx ON records USING gin(to_tsvector('english', caption_modality));"
    execute "CREATE INDEX caption_title_modality_idx ON records USING gin(to_tsvector('english', caption_title_modality));"
    
  end

  def self.down
  end
end
