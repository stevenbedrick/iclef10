class AdjustModalityColumns < ActiveRecord::Migration
  def self.up
    rename_column :records, :text_modality, :title_modality
    add_column :records, :caption_title_modality, :string
    
  end

  def self.down
    remove_column :records, :caption_title_modality
    rename_column :records, :new_column_name, :column_name
    
  end
end
