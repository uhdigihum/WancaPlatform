class Joint < ActiveRecord::Base
  belongs_to :language
  belongs_to :site
end
