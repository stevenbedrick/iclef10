class RecordController < ApplicationController
  
  def show
    @r = Record.find(params[:id])
  end
  
end
