class Site < ActiveRecord::Base
	validates :name, uniqueness: true

	has_many :links
  has_many :joints, :dependent => :destroy
  has_many :languages, :through => :joints
	#has_many :site_suggestions
	has_many :users, :through => :site_suggestions
	has_many :originals, :dependent => :destroy
	has_many :verified_links, -> {Link.verified}
end
