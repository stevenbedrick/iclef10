class IndexMhRecJoinTable < ActiveRecord::Migration
  def self.up
    add_index :mesh_terms_records, :record_id
    add_index :mesh_terms_records, :mesh_term_id
    
  end

  def self.down
    
    remove_index :mesh_terms_records, :record_id
    remove_index :mesh_terms_records, :mesh_term_id
    
  end
end
