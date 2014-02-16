class GameSetting < ActiveRecord::Base
  class << self
    def instance
      @@instance ||= find_or_create_by(id: 1)
    end

    def display_title
      content_title = instance.content_title.upcase.chars.join(" ")
      game_title = instance.game_title
      game_title.gsub(/<%(\s+)%>/) do
        "[reset][f:green]" + content_title.center($1.length)
      end
    end
  end
end