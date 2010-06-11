class CreateAssignedMeshTerms < ActiveRecord::Migration
  def self.up
    create_table :assigned_mesh_terms do |t|
      t.column :article_id, :integer
      t.column :mesh_term_id, :integer
      t.column :major_topic, :boolean
      t.timestamps
    end
    
    add_index :assigned_mesh_terms, :article_id
    add_index :assigned_mesh_terms, :mesh_term_id
    
  end

  def self.down
    drop_table :assigned_mesh_terms
  end
end
