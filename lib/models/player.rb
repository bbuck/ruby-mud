class Player < ActiveRecord::Base

  class << self
    def connections
      @@connections ||= {}
    end

    def connect(player_id, connection)
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