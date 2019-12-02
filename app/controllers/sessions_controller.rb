class SessionsController < ApplicationController
  def new

  end

  def create
    user = User.find_by username: params[:username]
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      session[:expires_in] = Time.current + 8.hours
      session[:show] = 'yes'
      session[:links] = '30'
      session[:verify] = 'all'
      redirect_after_login
    else
      redirect_to :back, notice: 'Wrong username or password'
    end
  end

  def destroy
    #session[:user_id] = nil
    #session[:expires_in] = nil
    #session[:show] = 'yes'
    #session[:links] = '30'
    #session[:verify] = 'all'
    reset_session
    redirect_to :root
  end


end