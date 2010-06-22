class Article < ActiveRecord::Base
  has_many :records, :class_name => "record", :foreign_key => "pmid"
  has_many :assigned_mesh_terms
  has_many :mesh_terms, :through => :assigned_mesh_terms
  
  def major_topics
    return self.assigned_mesh_terms.select { |m| m.major_topic? }
  end
  
end
