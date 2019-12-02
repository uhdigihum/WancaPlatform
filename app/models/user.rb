class User < ActiveRecord::Base
  has_secure_password

  has_many :suggestions
  has_many :links, :through => :suggestions
  has_many :site_suggestions
  has_many :sites, :through => :site_suggestions

  validates :username, uniqueness: true
  validates :username, length: {minimum: 3 }
  validates :email, presence: true
  validates :checkbutton, acceptance: true

end
