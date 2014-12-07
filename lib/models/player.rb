class Player < ActiveRecord::Base
  include BCrypt
  extend Memoist

  serialize :game_data, Hash
  serialize :permissions, BitMask

  has_many :tracking, class_name: "PlayerTracking"
  belongs_to :room
  has_many :created_rooms, class_name: "Room", foreign_key: :creator_id
  has_and_belongs_to_many :reputations

  scope :with_username, ->(username) { where("lower(username) = ?", username.downcase) }
  scope :online, -> { where(id: tcp_connections.keys) }
  scope :admins, -> { where(permissions: Game::Permissions.admin_permissions) }
  scope :celestials, -> { where(permissions: Game::Permissions.celestial_permissions) }
  scope :game_masters, -> { where(permissions: Game::Permissions.game_master_permissions) }
  scope :builders, -> { where(permissions: Game::Permissions.builder_permissions) }
  scope :events_team, -> { where(permissions: Game::Permissions.events_tema_permissions) }
  scope :without_permissions, -> { where(permissions: 0) }

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
          old_conn.write("You are being disconnected because your character was accessed by another client.")
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
      "[reset]"
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

  def write(text, opts = {})
    tcp_connections.each do |conn|
      conn.write(text, opts)
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
    permissions =~ Game::Permissions::BUILD_PERMISSION
  end

  def can_control?
    reload
    permissions =~ Game::Permissions::CONTROL_PERMISSION
  end

  def can_spawn?
    reload
    permissions =~ Game::Permissions::SPAWN_PERMISSION
  end

  def can_administrate?
    reload
    permissions =~ Game::Permissions::ADMIN_PERMISSION
  end

  def can_promote_to_admin?
    reload
    permissions =~ Game::Permissions::SUPER_ADMIN_PERMISSION
  end

  def make_builder
    permissions.reset << Game::Permissions.builder_permissions
    save
  end

  def builder?
    reload
    permissions =~ Game::Permissions::builder_permissions
  end

  def make_events_team
    permissions.reset << Game::Permissions.events_team_permissions
    save
  end

  def events_team?
    reload
    permissions =~ Game::Permissions.events_team_permissions
  end

  def make_game_master
    permissions.reset << Game::Permissions.game_master_permissions
    save
  end

  def game_master?
    reload
    permissions =~ Game::Permissions.game_master_permissions
  end

  def make_celestial
    permissions.reset << Game::Permission.celestial_permissions
    save
  end

  def celestial?
    reload
    permissions =~ Game::Permissions.celestial_permissions
  end

  def make_admin
    permissions.reset << Game::Permissions.admin_permissions
    save
  end

  def admin?
    reload
    permissions =~ Game::Permissions.admin_permissions
  end

  # --- ES Locks -------------------------------------------------------------

  def eleetscript_allow_methods
    [:display_name, :write]
  end
  memoize :eleetscript_allow_methods
end