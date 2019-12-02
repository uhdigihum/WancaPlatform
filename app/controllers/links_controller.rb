class LinksController < ApplicationController
  require 'uri'

  include Suggestions


  before_action :set_link, only: [:show, :edit, :update, :destroy]
  before_action :setSuggested, only: [:show, :edit]
  before_action :ensure_that_signed_in, except: [:show]
  before_action :ensure_that_chief, only: [:index, :destroy]
  before_action :ensure_that_admin, only: [:edit, :update, :new, :create]
  before_filter :store_return_to
  before_filter :store_link

  # GET /links
  # GET /links.json
  def index
  end

  # GET /links/1
  # GET /links/1.json
  def show
    if @link.show == false
      redirect_to languages_path, notice: 'Link you were looking for has been removed!' and return
    else
      @site = Site.find(@link.site_id)
      @link_lang = Language.find(@link.language_id)
      @orig_lang = Language.find(@link.orig_lang)
      @nro = params[:link_nro].to_i
      @next_nro = @nro + 1


      unless params[:language_id].nil?
        @lang_to_show = Language.find(params[:language_id])
        if session[:verify] == 'all'
          @links = @site.links.where(language_id: @lang_to_show.id, show: true).order('language_id', 'address')
        elsif session[:verify] == 'only'
          @links = @site.links.where(language_id: @lang_to_show.id, show: true, verified: true).order('language_id', 'address')
        else
          @links = @site.links.where(language_id: @lang_to_show.id, show: true, verified: false).order('language_id', 'address')
        end
        if session[:show] == 'no'
          @votes = Suggestion.where(user_id: current_user, language_id: @link_lang.id).uniq.pluck(:link_id)
          @links = @links.where(['id NOT IN (?)', @votes])
        end
        #@nroOfLinks = get_nro_of_links(@site, @lang_to_show.id)
        @nroOfLinks = @links.length
        @lang_to_go = @lang_to_show
      else
        @lang_to_show = @link_lang
        if session[:verify] == 'all'
          @links = @site.links.where(show: true).order('language_id', 'address')
        elsif session[:verify] == 'only'
          @links = @site.links.where(show: true, verified: true).order('language_id', 'address')
        else
          @links = @site.links.where(show: true, verified: false).order('language_id', 'address')
        end
        #@nroOfLinks = @site.links.where(show: true).count
        if session[:show] == 'no'
          @votes = Suggestion.where(user_id: current_user).uniq.pluck(:link_id)
          unless @votes.empty?
            links = []
            @links.each do |link|
              unless @votes.include? link.id
                links << link
              end
            end
            @links = links
          end
        end
        @nroOfLinks = @links.length
        @lang_to_go = nil
      end
      @next = @links[@nro]
      if @nro > 1
        @prev = @links[@nro -2]
      end
      @dom_id = params[:dom]
      @yesVotes = []
      @noVotes = []
      @dontKnow = []
      links = @link.suggestions.where(language_id: @link_lang.id)
      users = links.uniq.pluck(:user_id)
      users.each do |user|
        vote = links.where(user_id: user).last
        if vote.yes
          @yesVotes << vote
        elsif vote.no
          @noVotes << vote
        elsif vote.dont_know
          @dontKnow << vote
        end
      end
      @problem = ProblemLink.where(link_id: @link.id)
    end
  end

  # GET /links/new
  def new
    @link = Link.new
    @languages = Language.where('group_id < ?', 9).order(:name)
    if params[:address].nil?
      @address = ''
    else
      @address = params[:address]
    end
  end

  # GET /links/1/edit
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
    #@otherlangs = @otherlangs.reject!{ |l| not_wanted.include?(l.name)}
    @site = Site.find(params[:site_id])
    @lang = Language.find(params[:language_id])
    @nro = params[:link_nro]
    @next = true
    if params[:next].nil?
      @next = false
    end
    @dom = params[:dom]
  end

  # POST /links
  # POST /links.json
  def create
    address = params[:address].strip
    address = URI.escape(address)
    if address.nil? or address.empty?
      redirect_to :back, alert: 'Please, paste a link address to the field and select a language for it!' and return
    else
      if address =~ /\A#{URI::regexp(['http', 'https'])}\z/
        language_id = params[:language]
        if language_id.nil? or language_id.empty?
          redirect_to new_link_path(address: address), :alert => 'Please, select a language for the link!' and return
        end
        site_name = address.split('/')[2]
        site = Site.find_by_name(site_name)
        if site.nil?
          dom = Domain.find_by_name(site_name.split('.')[-1].upcase)
          if dom.nil?
            dom = Domain.find_by_name("OTHERS")
          end
          site = Site.create(name: site_name, domain_id: dom.id)
        end
        orig_lang = Language.find_by_name('Not identified')
        @link = Link.new(address: address, site_id: site.id, language_id: language_id, orig_lang: orig_lang.id, verified: true)

        respond_to do |format|
          if @link.save
            joint = Joint.where(site_id: site.id, language_id: language_id).last
            if joint.nil?
              joint = Joint.create(site_id: site.id, language_id: language_id)
            end
            joint.update_attribute(:number, joint.number+1)
            if site.show == false
              site.update_attribute(:show, true)
            end
            format.html { redirect_to site_path(site, language_id: language_id),  notice: 'Link was successfully created.' }
            format.json { render :show, status: :created, location: @link }
          else
            format.html { redirect_to site_path(site), :alert => 'Link already exists and could not be added' }
            format.json { render json: @link.errors, status: :unprocessable_entity }
          end
        end
      else
        redirect_to :back, alert: 'Please, paste a valid link address (with http:// or https://) to the field and select a language for it!' and return
      end
    end

  end

  # PATCH/PUT /links/1
  # PATCH/PUT /links/1.json
  def update
    languageId = params[:language_id]
    if params[:commit] == 'Change' or params[:show] == 'false'
      show = params[:show]
      siteId = @link.site_id
      if show == 'false'
        @link.update_attribute(:show, false)
        oldJoint = Joint.where(:language_id => languageId, :site_id => siteId).first
        oldJoint.update_attribute(:number, oldJoint.number-1)
      end
      if params[:commit] == 'Change'
        oldLangId = @link.language_id
        unless @link.verified
          @link.update_attribute(:language_id, languageId)

          unless Joint.where(:language_id => languageId, :site_id => siteId).present?
            Joint.create(:site_id => siteId, :language_id => languageId)
          end
          joint = Joint.where(:language_id => languageId, :site_id => siteId).first
          joint.update_attribute(:number, joint.number+1)
          oldJoint = Joint.where(:language_id => oldLangId, :site_id => siteId).first
          oldJoint.update_attribute(:number, oldJoint.number-1)
          Suggestion.create(link_id: @link.id, user_id: current_user.id, yes: true, language_id: languageId)

        end
      end

      if oldJoint.number == 0
        Joint.delete(oldJoint.id)
        if show == 'false'
          site = Site.find(siteId)
          links = site.links.where(show: true)
          if links.length == 0
            site.update_attribute(:show, false)
          end
        end
      end

      if params[:dom].to_i == 0
        dom_id = nil
      else
        dom_id = params[:dom].to_i
      end
      linkNro = params[:link_nro].to_i
      if session[:show] == 'no'
        @votes = Suggestion.where(user_id: current_user).uniq.pluck(:link_id)
      else
        @votes = [0]
      end
      if params[:lang_id].nil? && show == 'false'
        nextLink = Site.find(siteId).links.where(show: true).sort_by{ |l,n| n=Language.find(l.language_id).name }[linkNro - 1]
      else
        nextLink = Site.find(siteId).links.where(language_id: params[:lang_id], show: true).where('id NOT IN (?)', @votes)[linkNro - 1]
      end

      unless nextLink.nil?
        redirect_to link_path(nextLink, :link_nro => linkNro, :dom => dom_id, :language_id => params[:lang_id])
      else
        if show == 'false'
          redirect_to language_path(Language.find(languageId), :dom => dom_id, :page => session[:page])
        else
          redirect_to language_path(params[:lang_id], :dom => dom_id, :page => session[:page])
        end
      end
    else
        Suggestion.create(link_id: @link.id, user_id: current_user.id, :yes => true, language_id: languageId)
        redirect_to link_path(@link, :language_id => params[:lang_id], :link_nro => params[:link_nro])
    end
  end

  # DELETE /links/1
  # DELETE /links/1.json
  def destroy
    @link.destroy
    respond_to do |format|
      format.html { redirect_to links_url, notice: 'Link was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def setSuggested
      unless current_user.nil?
        @suggestions = @link.suggestions.where(user_id: current_user.id)
      else
        @suggestions = Suggestion.none
      end
      langs = @link.suggestions.where.not(language_id: nil).group(:language_id).count
      @langSuggs = setSuggestedLanguages(langs, @suggestions)
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_link
      @link = Link.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def link_params
      params.require(:link).permit(:address, :site_id, :language_id, :link_nro, :dom, :lang, :lang_id, :show)
    end

end
