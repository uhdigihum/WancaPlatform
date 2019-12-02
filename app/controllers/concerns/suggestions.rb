module Suggestions
  extend ActiveSupport::Concern

  module ClassMethods
    def setSuggestedLanguages
      @suggestions = @link.suggestions.where(user_id: current_user.id)
      langs = @link.suggestions.where.not(language_id: nil).group(:language_id).count
      @langSuggs = []
      langs.keys.each do |lang|
        langSugg = []
        langSugg << Language.find(lang)
        langSugg << langs[lang]
        if @suggestions.where(language_id: lang).exists?
          langSugg << true
        else
          langSugg << false
        end
        @langSuggs << langSugg
      end
    end
  end
end