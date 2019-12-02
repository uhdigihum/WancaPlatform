class SearchesController < ApplicationController

  require 'will_paginate/array'


  def index
    @query = URI.escape(params[:search]).downcase
    page = params[:page]
    #page = URI.escape(page)
    if Link.getbanned.include?(@query) || Link.is_number(@query)
      begin
        redirect_to :back, notice: "The query is too wide, please try with a more specific search" and return
      rescue ActionController::RedirectBackError
        redirect_to root_path
      end
    end
    @searches = Link.search(@query, page)
    @infos = []
    @searches.each do |link|
      info = []
      info << Language.getLinkLanguage(link)
      site_links = Site.find(link.site_id).links.where(language_id: link.language_id, show: true).order("address").select(:id).all.map(&:id)
      nro = site_links.index(link.id)
      info << nro
      @infos << info
    end
  end

end