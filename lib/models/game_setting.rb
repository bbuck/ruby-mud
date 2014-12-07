class GameSetting < ActiveRecord::Base
  class << self
    def instance
      @instance ||= find_or_create_by(id: 1)
      @instance.reload
      @instance
    end

    def display_title
      instance.game_title.erb({game_title: instance.content_title})
    end
  end
end