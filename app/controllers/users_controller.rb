class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update]
  before_action :ensure_that_signed_in, except: [:new, :create]
  before_action :ensure_that_chief, only: [:index]

  # GET /users
  # GET /users.json
  def index
    users = User.all
    @users = []
    users.each do |user|
      item = []
      item << user
      suggestions = Suggestion.where(user_id: user.id)
      if suggestions.length > 0
        item << suggestions.last.created_at
        language = Language.find(suggestions.last.language_id).name
        item << language
      else
        item << ''
        item << ''
      end
      @users << item
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    if @user.id == current_user.id or current_user.chief
      render
    else
      redirect_to :root
    end
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    if @user.id == current_user.id or current_user.chief
      render
    else
      redirect_to :root
    end
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if verify_recaptcha(:model => @user, :message => "Oh! It's error with reCAPTCHA!")
        if params[:commit] == 'Create' and @user.save
          format.html { redirect_to signin_path, notice: 'User was successfully created.' }
          format.json { render :show, status: :created, location: @user }
        else
          #ecaptcha.reset
          format.html { render :new }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    unless params[:show].nil?
      session[:show] = params[:show]
      redirect_to(session[:toggle_return])
    else
      unless params[:verify].nil?
        session[:verify] = params[:verify]
        if params[:verify] == 'only' || params[:verify] == 'all'
          session[:show] = 'yes'
        end
        if params[:verify] == 'not'
          session[:show] = 'no'
        end
        redirect_to(session[:toggle_return])
      else
        if verify_recaptcha(:model => @user, :message => "Oh! It's error with reCAPTCHA!")
          #user = User.find(params[:id])
          if @user.update(user_params)
            redirect_to current_user
          else
            redirect_to :back
          end
        else
          redirect_to :back
        end
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:username, :password, :password_confirmation, :show, :email, :firstname, :lastname, :checkbutton)
    end
end
