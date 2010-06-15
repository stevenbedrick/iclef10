class AssignedMeshTerm < ActiveRecord::Base
  belongs_to :article
  belongs_to :mesh_term

  def term
    self.mesh_term.term
  end

end
