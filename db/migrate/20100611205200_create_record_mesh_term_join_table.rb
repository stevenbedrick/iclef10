class CreateRecordMeshTermJoinTable < ActiveRecord::Migration
  def self.up
    create_table :mesh_terms_records, :id => false do |t|
      t.column :mesh_term_id, :integer
      t.column :record_id, :integer
    end
    
  end

  def self.down
    drop_table :mesh_terms_records
  end
end
