namespace :readtask do

  desc "Opens and reads the given file, adds new links (and sites) to the database. Expects the file to have the same form
as the textfiles/addLinks_example.txt file. Expects the database to have all the domains (e.g. 'fi' or 'de') and languages mentioned
in the file."
  task :read_file, [:filename] => :environment do |t, args|
    file = File.open(args[:filename], "r")
    while !file.eof
      lan = file.readline.strip
      site = file.readline.strip
      link = file.readline.strip
      begin
        dom = Domain.find_by_name(site.split('.')[-1].upcase)
        if dom.nil?
          dom = Domain.find_by_name("OTHERS")
        end
        newsite = Site.create name:site, domain_id:dom.id
        unless newsite.valid?
          newsite = Site.find_by_name(site)
        end
        language = Language.find_by_code(lan.downcase)
        unless newsite.links.find_by_address(link).present?
          begin
            newlink = Link.create address:link, language_id:language.id, site_id:newsite.id, orig_lang:language.id
          rescue
            retry
          end
          if newlink.valid?
            begin
              newsite.links << newlink
            rescue
              retry
            end
            begin
              unless Joint.where(:language_id => language.id, :site_id => newsite.id).present?
                Joint.create(:site_id => newsite.id, :language_id => language.id)
              end
              joint = Joint.where(:language_id => language.id, :site_id => newsite.id).first
              joint.update_attribute(:number, joint.number+1)
            rescue
              retry
            end
          end
        end
      rescue
        retry
      end
    end
    file.close
  end
end
