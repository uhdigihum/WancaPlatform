class LanguagesController < ApplicationController
  before_action :set_language, only: [:show, :edit, :update, :destroy]
  before_action :ensure_that_signed_in, except: [:index, :show]
  before_action :ensure_that_admin, only: [:edit, :destroy]
  before_filter :store_return_to, only: :show
  before_filter :store_return_after_toggle
  before_filter :store_return_from_languages, only: :index
  before_filter :store_hide, only: :show
  after_action :store_page_nro, only: :show

  # GET /languages
  # GET /languages.json
  def index
    order = params[:order] || 'name'

    unless params[:dom].nil?
      @domain = Domain.find(params[:dom])
      @languages = case order
                     when 'name' then get_domain_languages(@domain.id, 'name')
                     when 'group' then get_domain_languages(@domain.id, 'groups.name')
                     when 'code' then get_domain_languages(@domain.id, 'code')
                   end
    else
      @languages = case order
                     when 'name' then Language.where('group_id < ?', 9).includes(:group).order(:name)
                     when 'group' then Language.where('group_id < ?', 9).includes(:group).order('groups.name')
                     when 'code' then Language.where('group_id < ?', 9).includes(:group).order(:code)
                   end
    end
  end



  # GET /languages/1
  # GET /languages/1.json
  def show
    @count = 0
    @info = []
    @lang_links = Link.where(language_id: @lang.id, show: true).pluck(:id, :site_id, :verified)

    unless params[:dom].nil?
      @count = @lang.sites.where(domain_id: params[:dom], show: true).length
      #if session[:verify] == 'all'
        @sites = @lang.sites.includes(:links).where(domain_id: params[:dom], show: true).order(:name).paginate(:page => params[:page])
=begin
      elsif session[:verify] == 'only'
        @sites = @lang.sites.where(sites.link_id.in? @lang_links).where(domain_id: params[:dom], show: true).order(:name).paginate(:page => params[:page])
      else
        @sites = @lang.sites.includes(:links).where(domain_id: params[:dom], show: true).order(:name).paginate(:page => params[:page])
      end
=end
      @domain = Domain.find(params[:dom])
    else
      @count = @lang.joints.length
      #@sites = @lang.sites.includes(:links).where('sites.id IN (?)', @lang_sites).where(show: true).order(:name).paginate(:page => params[:page])
      @sites = @lang.sites.includes(:links).where(show: true).order(:name).paginate(:page => params[:page])
    end
    if session[:show] == 'no'
      @votes = Suggestion.where(user_id: current_user, language_id: @lang.id).uniq.pluck(:link_id)
    else
      @votes = []
    end
    @sites.each do |site|
      info = []
      nr_links = 0
      first = nil
      nr_show = 0
      #if site.id.in? @lang_sites
        @lang_links.each do |link|
          if link[1] == site.id
            if session[:verify] == 'only'
              verified = link[2]
            elsif session[:verify] == 'not'
              verified = !link[2]
            else
              verified = true
            end
            nr_links += 1

            if first == nil
                if verified
                  unless link[0].in?(@votes)
                    first = link[0]
                  end
                end
            end
            if verified
              unless link[0].in?(@votes)
                nr_show += 1
              end
            end
          end
        end
      #end
      info << site
      info << first
      info << nr_links
      info << nr_show
      @info << info
    end



  end

  # GET /languages/new
  def new
    @lang = Language.new
  end

  # GET /languages/1/edit
  def edit
  end

  # POST /languages
  # POST /languages.json
  def create
    @lang = Language.new(language_params)

    respond_to do |format|
      if @lang.save
        format.html { redirect_to @lang, notice: 'Language was successfully created.' }
        format.json { render :show, status: :created, location: @lang }
      else
        format.html { render :new }
        format.json { render json: @lang.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /languages/1
  # PATCH/PUT /languages/1.json
  def update
    respond_to do |format|
      if @lang.update(language_params)
        format.html { redirect_to @lang, notice: 'Language was successfully updated.' }
        format.json { render :show, status: :ok, location: @lang }
      else
        format.html { render :edit }
        format.json { render json: @lang.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /languages/1
  # DELETE /languages/1.json
  def destroy
    @lang.destroy
    respond_to do |format|
      format.html { redirect_to languages_url, notice: 'Language was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def store_page_nro
      session[:page] = @sites.current_page
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_language
      @lang = Language.includes(:group).find(params[:id])
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def language_params
      params.require(:lang).permit(:name, :group_id, :domain)
    end
end
