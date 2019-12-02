class Contact < MailForm::Base
  attribute :name, :validate => true
  attribute :email, :validate => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  #attribute :email
  attribute :message
  attribute :copy
  attribute :nickname, :captcha => true
  attribute :copyEmail
  validates_format_of :message, :without => /http/i

  def headers

    {
        :subject => "Wanca contact form",
        :to => "heidi.jauhiainen@helsinki.fi",
        :cc => email,
        #:Bcc => "heidi.jauhiainen@helsinki.fi",
        :from => %("#{name}" <#{email}>)
    }
  end
end