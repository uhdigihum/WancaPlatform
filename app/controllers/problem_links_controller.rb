class ProblemLinksController < ApplicationController
  before_action :ensure_that_chief, only: [:index, :update]

  def index
    links = ProblemLink.all
    @problem_links = []
    links.each do |link|
      problem = link.link
      if problem.show
        item = []
        item << problem
        item << User.find(link.user_id).username
        @problem_links << item
      end
    end
  end

  def create
    ProblemLink.create link_id: params[:link_id], user_id: current_user.id
    redirect_to :back, notice:'Thank you for reporting the problem with this link'
  end

  def update
    if params[:show].nil?
      problems = ProblemLink.where(link_id: params[:id])
      problems.each do |link|
        ProblemLink.destroy(link)
      end
      QuestionableLink.create(link_id: params[:id])
    else
      link = Link.find(params[:id])
      link.update_attribute(:show, false)
      oldJoint = Joint.where(:language_id => link.language_id, :site_id => link.site_id).first
      oldJoint.update_attribute(:number, oldJoint.number-1)
      if oldJoint.number == 0
        Joint.delete(oldJoint.id)
        site = Site.find(link.site_id)
        links = site.links.where(show: true)
        if links.length == 0
          site.update_attribute(:show, false)
        end
      end
    end
    redirect_to :back
  end
end