class Player < ActiveRecord::Base
  include BCrypt

  has_many :tracking, class_name: "PlayerTracking"
  belongs_to :room

  scope :with_username, ->(username) { where("lower(username) = ?", username.downcase) }
  scope :online, -> { where(id: connections.keys) }

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

    def disconnect(player, connection)
      connections[player.id].delete(connection)
      Laeron.config.logger.info("Player #{player.username} disconnected.")
    end

    def connect(player, connection)
      player_id = if player.is_a?(Player)
        player.id
      else
        player = Player.find(player)
        player.id
      end
      ip_addr = Socket.unpack_sockaddr_in(connection.get_peername)[1]
      tracking = player.tracking.find_or_create_by(ip_address: ip_addr)
      tracking.update_attributes(connection_count: (tracking.connection_count || 0) + 1)
      if connections[player_id] && connections[player_id].length > 0
        connections[player_id].each do |old_conn|
          old_conn.send_text("You are being disconnected because your character was accessed by another client.")
          old_conn.quit
        end
        connections[player_id].clear
      end
      (connections[player_id] ||= []) << connection
    end

    def online?(player)
      connections[player.id] && connections[player.id].length > 0
    end
  end

  def online?
    Player.connections[id] && Player.connections[id].length > 0
  end

  def connection
    if online?
      Player.connections[id].first
    else
      nil
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
    if new_password
      @password = Password.create(new_password)
      new_hash[:password_hash] = @password
    end
    super(new_hash)
  end
end