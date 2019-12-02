class Link < ActiveRecord::Base
  has_one(:language)
  has_many :suggestions
  has_many :users, :through => :suggestions

  scope :verified, -> { where(verified: :true)}


  validates :address, uniqueness: true

  def self.search(query, page)
    where('address like ?', "%#{query}%").where(show: true).order("address").paginate(:page => page)
  end

  def self.getbanned
    banned = ['http', 'http:', 'http:/', 'http://', 'http://w', 'http://ww', 'http://www', 'https', 'https:',
              'https:/', 'https://', 'https://w', 'https://ww', 'httsp://www', 'www', '.www', 'www.', '.www.',
              'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'x', 'y', 'z',
              'fi', '.fi', 'no', '.no', 'se', '.se', 'ru', '.ru', 'hu', '.hu', 'lv', '.lv', 'com', '.com', 'net', '.net', 'org', '.org']
  end

  def self.is_number(word)
    if word.to_i > 0 || word == '0'
      return true
    end
  end
end
