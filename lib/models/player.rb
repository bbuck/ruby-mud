class Player < ActiveRecord::Base
  include BCrypt

  class << self
    def connection_list
      list = []
      connections.each do |id, conns|
        list.concat(conns)
      end
      list
    end

    def connections
      @@connections ||= {}
    end

    def connect(player, connection)
      player_id = if player.is_a?(Player)
        player.id
      else
        player
      end
      (connections[player_id] ||= []) << connection
    end
  end

  # Password functions
  def password
    @password || Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  def update_attributes(hash)
    new_hash = hash.dup
    new_password = new_hash.delete(:password)
    @password = Password.create(new_password)
    new_hash[:password_hash] = @password
  end
end