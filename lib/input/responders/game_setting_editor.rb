module Input
  module Responder
    class GameSettingEditor < Base
      # --- Template Helpers -------------------------------------------------

      def write_game_setting_menu
        render("responder.game_setting_editor.main_menu", {settings: game_settings})
      end

      # --- Public Helpers ---------------------------------------------------

      def edit_settings
        change_input_state(:game_setting_editor)
        write_game_setting_menu
      end

      # --- Responders -------------------------------------------------------

      responders_for_mode :edit_content_title do
        parse_input_with(/\A(.+?)\z/) do |name|
          binding.pry
          game_settings.update_attributes(content_title: name)
          clear_mode
          write_game_setting_menu
        end
      end

      parse_input_with(/\A1\z/) do
        create_responder(Editor).open_editor(game_settings, :game_title, allow_colors: true) do
          write_game_setting_menu
        end
      end

      parse_input_with(/\A2\z/) do
        change_mode(:edit_content_title)
        write_without_prompt("[f:green]Enter new content title >>")
      end

      parse_input_with(/\A3\z/) do
      end

      parse_input_with(/\A4\z/) do
        change_input_state(:standard)
        write_room_description
      end

      # --- Private Helpers --------------------------------------------------

      def game_settings
        GameSetting.instance
      end
    end
  end
end

Input::Manager.register_responder(:game_setting_editor, Input::Responder::GameSettingEditor)
