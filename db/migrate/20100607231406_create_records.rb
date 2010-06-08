class CreateRecords < ActiveRecord::Migration
  def self.up
    create_table :records do |t|
      t.column :figure_id, :integer
      t.column :figure_url, :string
      t.column :caption, :text
      t.column :title, :string, :limit => 512
      t.column :pmid, :integer
      t.column :article_url, :string
      t.column :image_url, :string
      t.column :image_local_name, :string
      t.column :full_caption, :text
      t.column :parsed_caption, :text
      t.column :text_modality, :string
      t.column :caption_modality, :string
      t.timestamps
    end
    
  end
  
  

  def self.down
    drop_table :records
  end
end
