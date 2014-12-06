class Player < ActiveRecord::Base
  include BCrypt
  extend Memoist

  BUILD_PERMISSION = 1
  CONTROL_PERMISSION = 2
  SPAWN_PERMISSION = 4
  ADMIN_PERMISSION = 8
  SUPER_ADMIN_PERMISSION = 16

  serialize :game_data, Hash

  has_many :tracking, class_name: "PlayerTracking"
  belongs_to :room
  has_many :created_rooms, class_name: "Room", foreign_key: :creator_id
  has_and_belongs_to_many :reputations

  scope :with_username, ->(username) { where("lower(username) = ?", username.downcase) }
  scope :online, -> { where(id: tcp_connections.keys) }

  class << self
    # --- Connection Helpers -------------------------------------------------

    def each_tcp_connection(&block)
      tcp_connections.each do |id, conns|
        conns.each(&block)
      end
    end

    def tcp_connections
      @tcp_connections ||= {}
    end

    def disconnect(player, connection)
      tcp_connections[player.id].delete(connection)
      tcp_connections.delete(player.id) if tcp_connections[player.id].count == 0
      Laeron.config.logger.info("Player #{player.username} disconnected.")
    end

    def connect(player, connection)
      player_id = if player.is_a?(Player)
        player.id
      else
        player = Player.find(player)
        player.id
      end
      ip_addr = connection.ip_addr
      tracking = player.tracking.find_or_create_by(ip_address: ip_addr)
      tracking.update_attributes(connection_count: (tracking.connection_count || 0) + 1)
      if tcp_connections[player_id] && tcp_connections[player_id].length > 0
        tcp_connections[player_id].each do |old_conn|
          old_conn.send_text("You are being disconnected because your character was accessed by another client.")
          old_conn.quit
        end
        tcp_connections[player_id].clear
      end
      (tcp_connections[player_id] ||= []) << connection
    end

    def online?(player)
      tcp_connections[player.id] && tcp_connections[player.id].length > 0
    end
  end

  # --- Display Helpers ---------------------------------------------------------------

  def display_name
    name_color = if admin?
      "[f:cyan:b]"
    elsif celestial?
      "[f:white:b]"
    elsif game_master?
      "[f:yellow:b]"
    elsif builder?
      "[f:green:b]"
    else
      ""
    end
    name_color + username
  end

  def display_prompt
    "\n[f:green]PROMPT >>\n\n"
  end

  def display_description
    unless description.blank?
      "[f:green]#{description}"
    else
      "#{display_name} [f:green]stands before you."
    end
  end

  # --- Connection Helpers ----------------------------------------------------

  def disconnect
    Player.disconnect(self, tcp_connection)
  end

  def online?
    Player.tcp_connections[id] && Player.tcp_connections[id].length > 0
  end

  def tcp_connection
    if online?
      Player.tcp_connections[id].first
    else
      nil
    end
  end

  def tcp_connections
    if online?
      Player.tcp_connections[id]
    else
      []
    end
  end

  def send_text(text, opts = {})
    tcp_connections.each do |conn|
      conn.send_text(text, opts)
    end
  end

  # --- Password functions ----------------------------------------------------

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

  # --- Permission Helpers ---------------------------------------------------

  def can_build?
    reload
    permissions & BUILD_PERMISSION == BUILD_PERMISSION
  end

  def can_control?
    reload
    permissions & CONTROL_PERMISSION == CONTROL_PERMISSION
  end

  def can_spawn?
    reload
    permissions & SPAWN_PERMISSION == SPAWN_PERMISSION
  end

  def can_administrate?
    reload
    permissions & ADMIN_PERMISSION == ADMIN_PERMISSION
  end

  def can_promote_to_admin?
    reload
    permissions & SUPER_ADMIN_PERMISSION == SUPER_ADMIN_PERMISSION
  end

  def make_builder
    update_attribute(:permissions, BUILD_PERMISSION & SPAWN_PERMISSION)
  end

  def builder?
    permissions == (BUILD_PERMISSION | SPAWN_PERMISSION)
  end

  def make_events_team
    update_attribute(:permissions, CONTROL_PERMISSION | SPAWN_PERMISSION)
  end

  def events_team?
    permissions = (CONTROL_PERMISSION | SPAWN_PERMISSION)
  end

  def make_game_master
    update_attribute(:permissions, ADMIN_PERMISSION | CONTROL_PERMISSION | SPAWN_PERMISSION)
  end

  def game_master?
    permissions == (ADMIN_PERMISSION | CONTROL_PERMISSION | SPAWN_PERMISSION)
  end

  def make_celestial
    update_attribute(:permission, BUILD_PERMISSION | ADMIN_PERMISSION | CONTROL_PERMISSION | SPAWN_PERMISSION)
  end

  def celestial?
    permissions == (BUILD_PERMISSION | ADMIN_PERMISSION | CONTROL_PERMISSION | SPAWN_PERMISSION)
  end

  def make_admin
    update_attribute(:permissions, BUILD_PERMISSION | ADMIN_PERMISSION | CONTROL_PERMISSION | SPAWN_PERMISSION | SUPER_ADMIN_PERMISSION)
  end

  def admin?
    permissions == (BUILD_PERMISSION | ADMIN_PERMISSION | CONTROL_PERMISSION | SPAWN_PERMISSION | SUPER_ADMIN_PERMISSION)
  end

  # --- ES Locks -------------------------------------------------------------

  def eleetscript_allow_methods
    [:display_name, :send_text]
  end
  memoize :eleetscript_allow_methods
end