class ProblemLink < ActiveRecord::Base
  belongs_to :link

  validates :link_id, uniqueness: true
end
