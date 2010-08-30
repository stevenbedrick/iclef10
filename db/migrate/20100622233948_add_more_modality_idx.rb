class AddMoreModalityIdx < ActiveRecord::Migration
  def self.up
#    execute "CREATE INDEX jaykc_modality_idx ON records USING gin(to_tsvector('english', jaykc_title_modality));"
    execute "CREATE INDEX caption_title_modality_idx_concat on records using gin(to_tsvector('english', caption_modality || ' ' || title_modality))"
    
    execute "CREATE INDEX all_modality_idx on records using gin(to_tsvector('english', caption_modality || ' ' || title_modality || ' ' || jaykc_modality))"
  end

  def self.down
  end
end
