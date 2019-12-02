class ContactsController < ApplicationController

  def new
    @contact = Contact.new
    if current_user
      user = current_user
      @contact.name = "#{user.firstname} #{user.lastname}"
      @contact.email = user.email
      @contact.copy = 0
    end
  end

  def create
    @contact = Contact.new(params[:contact])
    @contact.request = request
    if @contact.deliver
      flash[:notice] = "Thank you for your message. We will contact you soon!"
      redirect_to :languages
    else
      flash.now[:error] = "Cannot send message!"
      render :new
    end
  end

  def edit
    user = current_user
    @contact = user
    #@contact.name = "#{user.firstname} #{user.lastname}"
    render :new
  end
end