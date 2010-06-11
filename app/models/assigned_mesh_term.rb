class AssignedMeshTerm < ActiveRecord::Base
  belongs_to :article
  belongs_to :mesh_term
end
