class SiteSuggestionsController < ApplicationController
  def create
    SiteSuggestion.create(site_id: params[:site], user_id: current_user.id, language_id: params[:language_id])
    redirect_to site_path(params[:site])
  end
end