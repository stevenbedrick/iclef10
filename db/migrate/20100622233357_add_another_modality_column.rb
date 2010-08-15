class AddAnotherModalityColumn < ActiveRecord::Migration
  def self.up
    add_column :records, :jaykc_modality, :string

  end

  def self.down
    remove_column :records, :jaykc_modality
  end
end
