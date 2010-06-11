class CreateMeshTerms < ActiveRecord::Migration
  def self.up
    create_table :mesh_terms do |t|
      t.column :term, :string
      t.timestamps
    end
    
    add_index :mesh_terms, :term
  end

  def self.down
    remove_index :mesh_terms, :term
    drop_table :mesh_terms
  end
end
