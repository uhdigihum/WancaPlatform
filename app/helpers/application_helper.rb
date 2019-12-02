module ApplicationHelper

  def get_nro_of_links(site, lang_id)
      first = site.joints.where(language_id: lang_id).first

    unless first.nil?
      first.number
    else
      0
    end
  end

  def no_edit
    return true if current_user
  end

  def get_domain_languages(id, order)
    langs = []
    languages = Language.where('group_id < ?', 9).includes(:group).order(order)
    languages.each do |lang|
      if is_in_domain(id, lang) > 0
        langs << lang
      end
    end
    return langs
  end

  def domain_site_count(id)
    count = 0
    @languages.each do |language|
      unless language.group_id > 8
        count += is_in_domain(id, language)
      end
    end
    return count
  end

  def domain_language_count(id)
    count = 0
    @languages.each do |language|
      unless language.group_id > 8
        if is_in_domain(id, language) > 0
          count +=1
        end
      end
    end
    return count
  end

  def domain_group(id)
    groups = Set.new
    get_domain_languages(id, 'groups.name').each do |language|
      unless language.group_id > 8
          groups.add?(Group.find(language.group_id))
      end
    end
    return groups
  end

  def domain_group_count(id)
    return domain_group(id).size()
  end

  def is_in_domain(id, lang)
    return lang.sites.where(domain_id: id, show:true).count.to_i
  end

  def nr_of_link_on_page(nr)
    session[:links] = nr
  end
end
