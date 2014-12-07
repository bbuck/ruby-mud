module Game
  module Permissions
    BUILD_PERMISSION = 0b00001
    CONTROL_PERMISSION = 0b00010
    SPAWN_PERMISSION = 0b00100
    ADMIN_PERMISSION = 0b01000
    SUPER_ADMIN_PERMISSION = 0b10000

    def admin_permissions
      (BUILD_PERMISSION | ADMIN_PERMISSION | CONTROL_PERMISSION | SPAWN_PERMISSION | SUPER_ADMIN_PERMISSION)
    end

    def celestial_permissions
      (BUILD_PERMISSION | ADMIN_PERMISSION | CONTROL_PERMISSION | SPAWN_PERMISSION)
    end

    def game_master_permissions
      (ADMIN_PERMISSION | CONTROL_PERMISSION | SPAWN_PERMISSION)
    end

    def builder_permissions
      (BUILD_PERMISSION | SPAWN_PERMISSION)
    end

    def events_team_permissions
      (CONTROL_PERMISSION | SPAWN_PERMISSION)
    end

    module_function *instance_methods
  end
end