class GameSetting < ActiveRecord::Base
  class << self
    def instance
      @@instance ||= find_or_create_by(id: 1)
    end

    def display_title
      content_title = instance.content_title.upcase.chars.join(" ").center(64)
      content_title = "[reset][f:green]#{content_title}"
      game_title = instance.game_title
      game_title.gsub(/<%\s{64}%>/, content_title)
    end
  end
end