class Language < ActiveRecord::Base
#	has_and_belongs_to_many :sites
  has_many :joints
  has_many :sites, :through => :joints
	has_many :links
  belongs_to :group
  has_many :originals

  def self.getLinkLanguage(link)
    Language.find(link.language_id)
  end
end
