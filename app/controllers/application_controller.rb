class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :set_cache_buster
  #before_filter :set_locale
  before_filter :check_session
  before_filter :set_last_seen

  include ApplicationHelper

  helper_method :current_user
  helper_method :get_nro_of_links

  def current_user
    return nil if session[:user_id].nil?
    User.find(session[:user_id])
  end

  def ensure_that_signed_in
    redirect_to signin_path, notice: 'You should be signed in' if current_user.nil?
  end

  def ensure_that_admin
    redirect_to :root unless current_user.admin
  end

  def ensure_that_chief
    redirect_to :back unless current_user and current_user.chief
  end


  def set_last_seen
    session[:last_seen] = Time.now
    session[:expires_in] = Time.now + 8.hours
  end


  #def set_locale
   # I18n.locale = params[:locale] || I18n.default_locale
  #end

  #def default_url_options(options={})
   # { :locale => I18n.locale }
  #end

  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def store_return_to
    session[:return_to] = request.url
  end

  def store_return_from_languages
    session[:return_from_languages] = request.url
  end

  def redirect_after_login
    unless session[:return_to].nil?
      redirect_to(session[:return_to])
    else
      redirect_to :groups
    end
  end

  def store_return_after_toggle
    session[:toggle_return] = request.url
  end

  def store_hide
    session[:hide_return] = request.url
  end

  def store_link
    session[:link] = request.url
  end

  def setSuggestedLanguages(langs, suggestions)
    @langSuggs = []
    langs.keys.each do |lang|
      langSugg = []
      langSugg << Language.find(lang)
      langSugg << langs[lang]
      if suggestions.where(language_id: lang).exists?
        langSugg << true
      else
        langSugg << false
      end
      @langSuggs << langSugg
    end
    return @langSuggs
  end

  def check_session
    unless session[:expires_in].nil?
      if session[:expires_in] < Time.current
        #session[:user_id] = nil
        #session[:expires_in] = nil
        #session[:show] = 'yes'
        #session[:links] = '30'
        #session[:verify] = 'all'
        reset_session
        redirect_to :root
      end
    end

  end

end
