module Input
  module Responder
    class AdminCommands < Base
      # --- Template Helpers -------------------------------------------------
      # --- Public Helpers ---------------------------------------------------
      # --- Responders -------------------------------------------------------

      before_responder :has_admin_permissions?

      parse_input_with(/\A@edit game settings\z/) do
        create_responder(GameSettingEditor).edit_settings
      end

      # --- Private Helpers --------------------------------------------------

      def has_admin_permissions?
        unless player.can_administrate?
          write_not_authorized
          false
        end
      end
    end
  end
end

Input::Manager.register_responder(:standard, Input::Responder::AdminCommands)
