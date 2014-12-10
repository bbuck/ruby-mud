module Input
  module Responder
    class GameSettingEditor < Base
      # --- Template Helpers -------------------------------------------------

      def write_game_setting_menu
        render("responder.game_setting_editor.main_menu", {settings: game_settings})
      end

      def write_set_room_commands_help
        render("responder.game_setting_editor.set_room_help")
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

      responders_for_mode :set_initial_room do
        parse_input_with(/\Aback\z/) do
          clear_mode
          write_game_setting_menu
        end

        parse_input_with(/\Asearch (.+?)\z/) do |query|
          rooms = ::Room.name_like(query).limit(10)
          if rooms.count > 0
            room_str = rooms.map { |r| "[reset]##{r.id} - [f:white:b]#{r.display_name}" }.join("\n")
            write_without_prompt("\n#{room_str}\n>>")
          else
            write_without_prompt("[f:green]No rooms matching \"#{query}\" were found.")
          end
        end

        parse_input_with(/\Aset #?(\d+?)\z/) do |room_id|
          begin
            room = ::Room.find(room_id)
            game_settings.update_attributes(initial_room_id: room.id)
            clear_mode
            write_game_setting_menu
          rescue ActiveRecord::RecordNotFound => e
            write_without_prompt("[f:yellow:b]There is no room with the ID ##{room_id}, try searching for the right one?")
          end
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
        change_mode(:set_initial_room)
        write_set_room_commands_help
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
