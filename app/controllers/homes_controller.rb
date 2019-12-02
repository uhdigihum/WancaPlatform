class HomesController < ApplicationController
  before_filter :store_return_after_toggle

  def index
    not_wanted = Language.where(group_id: 9).pluck(:id)
    #@nro_of_links = Link.where(show: true).where('language_id NOT IN (?)', languages).length
    @nro_of_links = Joint.where('language_id NOT IN (?)', not_wanted).sum(:number)
    @nro_of_sites = Joint.where('language_id NOT IN (?)', not_wanted).select(:site_id).uniq.length
    #languages = Language.where('group_id IN (?)', 9).pluck(:id)
    @languages = Joint.where('language_id NOT IN (?)', not_wanted).select(:language_id).uniq.length
  end

  def show
  end

  def new

  end
end