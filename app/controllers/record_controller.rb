class RecordController < ApplicationController
  
  def show
    @r = Record.find(params[:id], :include => [:mesh_terms, {:article => {:assigned_mesh_terms => :mesh_term}}])
  end
  
end
