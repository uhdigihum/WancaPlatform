class SitesController < ApplicationController
  include Suggestions

  require 'will_paginate/array'
  #require 'zip'

  before_action :set_site, only: [:show, :edit, :update, :destroy]
  #before_action :setSuggested, only: [:show, :edit]
  #before_action :setOriginals, only: [:show, :edit]
  before_action :ensure_that_signed_in, except: [:index, :show]
  before_action :ensure_that_admin, only: [:destroy]
  before_filter :store_return_to
  before_filter :store_return_after_toggle
  after_action :store_page_nro, only: :show

  #helper_method :nr_of_links_on_page

  # GET /sites
  # GET /sites.json
  def index
    @sites = Site.all
  end

  # GET /sites/1
  # GET /sites/1.json
  def show
    #if @site.show == false
     # redirect_to languages_path, notice: 'Link you were looking for has been removed!' and return
    #else
      unless params[:link].nil?
        links = @site.links.where(language_id: params[:language_id].to_i, show: true)
        redirect_to link_path(links.first, :language_id => params[:language_id], :link_nro => params[:link_nro])
      end
      if session[:show] == 'no'
        #@votes = Suggestion.where(user_id: current_user).uniq.pluck(:link_id)
        @votes = [0]
        sitelinks = @site.links.where(show: true).pluck(:id)
        @suggs = Suggestion.where(user_id: current_user).where('link_id IN (?)', sitelinks).uniq
        @suggs.each do |sugg|
          link = Link.find(sugg.link_id)
          if link.site_id == @site.id
            if link.language_id == sugg.language_id
              @votes << link.id
            end
          end
        end
      else
        @votes = [0]
      end
      if session[:links].nil?
        nr_of_links = 30
      else
        nr_of_links = session[:links].to_i
      end
      if params[:language_id].nil?
        @lang = nil
        if session[:verify] == 'all'
          @links = @site.links.where(show: true).where('id NOT IN (?)', @votes).order('language_id', 'address').paginate(:page => params[:page], :per_page => nr_of_links)
        elsif session[:verify] == 'only'
          @links = @site.links.where(show: true, verified: true).order('language_id', 'address').paginate(:page => params[:page], :per_page => nr_of_links)
        else
          @links = @site.links.where(show: true, verified: false).where('id NOT IN (?)', @votes).order('language_id', 'address').paginate(:page => params[:page], :per_page => nr_of_links)
        end
        @sitelangs = @site.languages
        #@all_count = @site.links.where(show: true).count
        @all_count = @site.joints.sum(:number)
        if session[:show] == 'no'
          @count = @site.links.where(show: true).where('id NOT IN (?)', @votes).length
        else
          @count = @all_count
        end
      else
        @lang = Language.find(params[:language_id])
        if session[:verify] == 'all'
          @links = @site.links.where(language_id: @lang.id, show: true).where('id NOT IN (?)', @votes).order("address").paginate(:page => params[:page], :per_page => nr_of_links)
        elsif session[:verify] == 'only'
          @links = @site.links.where(language_id: @lang.id, show: true, verified: true).order("address").paginate(:page => params[:page], :per_page => nr_of_links)
        else
          @links = @site.links.where(language_id: @lang.id, show: true, verified: false).where('id NOT IN (?)', @votes).order("address").paginate(:page => params[:page], :per_page => nr_of_links)
        end
        @sitelangs = [@lang]
        @all_count = @site.joints.where(language_id: @lang.id).sum(:number)
        if session[:show] == 'no'
          @count = @site.links.where(language_id: @lang.id, show: true).where('id NOT IN (?)', @votes).length
          #@count = @links.length
        else
          @count = @all_count
        end

      end
    #end
  end

  # GET /sites/new
  def new
    @site = Site.new
  end

  # GET /sites/1/edit
  def edit
=begin
    langs = Language.all.order(:name).group_by{ |lang| lang.group_id}.reject{ |item| item.nil? }.sort
    @languages = []
    for i in 0..7
      for j in 0..langs[i][1].length-1
        @languages << langs[i][1][j]
      end
    end
=end
    @languages = Language.where('group_id NOT IN (?)', 9).order(:name)
    @other = Language.find_by_name('Other')
    not_wanted_ids = Language.where('name IN (?)', ['Other', 'Not identified']).pluck(:id)
    @otherLangs = Language.where(group_id: 9).where('id NOT IN (?)', not_wanted_ids).order(:name)
    @sitelangs = @site.languages

  end

  # POST /sites
  # POST /sites.json
  def create
    @site = Site.new(site_params)

    respond_to do |format|
      if @site.save
        format.html { redirect_to @site, notice: 'Site was successfully created.' }
        format.json { render :show, status: :created, location: @site }
      else
        format.html { render :new }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
    if params[:commit] == 'Change'
      languageId = params[:language_id]
      links = @site.links
      links.each do |link|
        unless link.verified
          oldLangId = link.language_id
          link.update_attribute(:language_id, languageId)
          if link.show
            unless Joint.where(:language_id => languageId, :site_id => @site.id).present?
              Joint.create(:site_id => @site.id, :language_id => languageId)
            end
            joint = Joint.where(:language_id => languageId, :site_id => @site.id).first
            joint.update_attribute(:number, joint.number+1)
            oldJoint = Joint.where(:language_id => oldLangId, :site_id => @site.id).first
            oldJoint.update_attribute(:number, oldJoint.number-1)
            if oldJoint.number == 0
              Joint.delete(oldJoint.id)
            end
            Suggestion.create(link_id: link.id, user_id: current_user.id, yes: true, language_id: languageId)
          end
        end
      end

      redirect_to(session[:hide_return])

    elsif params[:show] == 'false'
      links = @site.links
      links.each do |link|
        link.update_attribute(:show, false)
      end
      joints = Joint.where(site_id: @site.id)
      joints.each do |joint|
        Joint.destroy(joint.id)
      end
      @site.update_attribute(:show, false)
      redirect_to(session[:hide_return])
    else
      links = params[:votes]
      if links.nil?
        redirect_to :back and return
      end
      if params[:commit] == 'Yes'
        links.each do |link|
          link = link.split(' ').map { |s| s.to_i }
          Suggestion.create(link_id: link[0], user_id: current_user.id, yes: true, language_id: link[1])
        end
      elsif params[:commit] == 'No'
        links.each do |link|
          link = link.split(' ').map { |s| s.to_i }
          Suggestion.create(link_id: link[0], user_id: current_user.id, no: true, language_id: link[1])
        end
      elsif params[:commit] == "Don't know"
        links.each do |link|
          link = link.split(' ').map { |s| s.to_i }
          Suggestion.create(link_id: link[0], user_id: current_user.id, dont_know: true, language_id: link[1])
        end
      elsif params[:commit] == 'VERIFY all checked links'
        links.each do |link|
          link = link.split(' ').map { |s| s.to_i }
          link_proper = Link.find(link[0])
          link_proper.update_attribute(:verified, true)
          Suggestion.create(link_id: link_proper.id, user_id: current_user.id, yes: true, language_id: link[1])
        end
      end
      redirect_to :back
    end
  end

  # DELETE /sites/1
  # DELETE /sites/1.json
  def destroy
    @site.destroy
    respond_to do |format|
      format.html { redirect_to sites_url, notice: 'Site was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def nr_of_links_on_page
    session[:links] = params[:links].to_i
    if params[:lang].to_i == 0
      lang = nil
    else
      lang = params[:lang].to_i
    end
    redirect_to site_path(params[:site], :language_id => lang, :page => 1)
  end

  private

    def store_page_nro
      session[:page] = @links.current_page
    end

    def setSuggested
      unless current_user.nil?
        @suggestions = @site.site_suggestions.where(user_id: current_user.id)
      else
        @suggestions = Suggestion.none
      end
      langs = @site.site_suggestions.group(:language_id).count
      @langSuggs = setSuggestedLanguages(langs, @suggestions)
    end

    def setOriginals
=begin
      site_originals = Original.where(site_id: @site.id)
      @original_langs = []
      for i in 0..site_originals.length-1
        @original_langs << Language.find(site_originals[i].language_id)
      end
=end
      site_links = @site.links
      @original_langs = []
      site_links.each do |link|
        unless @original_langs.include(link)
          @original_langs << link
        end
      end
  end

    # Use callbacks to share common setup or constraints between actions.
    def set_site
      @site = Site.find(params[:id])
      if @site.show == false
        redirect_to languages_path, notice: 'Site you were looking for has been removed!'
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def site_params
      params.require(:site).permit(:name, :language_id, :show)
    end
end
