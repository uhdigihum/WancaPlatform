class SuggestionsController < ApplicationController
  def create
    unless params[:verify].nil?
      link = Link.find(params[:link])
      link.update_attribute(:verified, true)
    end
    Suggestion.create(link_id: params[:link], user_id: current_user.id, yes: params[:yes], no: params[:no], language_id: params[:language_id], dont_know: params[:dont_know])
    link_nro = params[:link_nro].to_i
    if session[:show] == 'no'
      link_nro = params[:link_nro].to_i-1
    end
    if params[:next].nil?
      redirect_to language_path(params[:language_id], :dom => params[:dom], :page => session[:page])
    else
      redirect_to link_path(params[:next], :link_nro => link_nro, :dom => params[:dom], :language_id => params[:lang])
    end
  end
end