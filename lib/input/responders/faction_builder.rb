module Input
  module Responder
    class FactionBuilder < Base
      # --- Template Helpers -------------------------------------------------

      def send_faction_builder_menu
        editing_faction.reload
        send_no_prompt(Helpers::View.render("responder.faction_builder.main_menu", faction: editing_faction))
      end

      def send_hostility_menu
        send_no_prompt(Helpers::View.render("responder.faction_builder.hostility_menu", faction: editing_faction))
      end

      # --- Public Helpers ---------------------------------------------------

      def edit_faction(faction)
        change_input_state(:faction_builder)
        self.internal_state = {faction: faction}
        send_faction_builder_menu
      end

      # --- Responders -------------------------------------------------------

      responders_for_mode :edit_name do
        parse_input_with(/\A(.+?)\z/) do |name|
          editing_faction.update_attributes(name: name)
          send_faction_builder_menu
          clear_mode
        end
      end

      responders_for_mode :edit_reputation do
        parse_input_with(/\A(\d+?)\z/) do |reputation|
          rep_name = internal_state.delete(:reputation_name)
          editing_faction.update_attribute("#{rep_name}_tier".to_sym, reputation)
          internal_state.delete(:reputation_name)
          send_faction_builder_menu
          clear_mode
        end

        parse_input_with(/\A.*?\z/) do
          rep_name = internal_state[:reputation_name]
          send_no_prompt("[f:green]You must enter a numeric value for repuations!")
          send_no_prompt("[f:green]Enter new repuation value for \"#{rep_name.humanize.titleize}\" >>")
        end
      end

      responders_for_mode :edit_hostility do
        parse_input_with(/\A(\d)\z/) do |hostility|
          values = ::Faction.hostility.numeric_values
          hostility = hostility.to_i
          if values.include?(hostility)
            editing_faction.update_attributes(hostility: hostility)
            send_faction_builder_menu
            clear_mode
          else
            send_no_prompt("[f:green]The hostility \"#{hostility}\" is not valid.")
            send_hostility_menu
          end
        end
      end

      parse_input_with(/\A1\z/) do
        change_mode(:edit_name)
        send_no_prompt("[f:green]Enter new name >>")
      end

      parse_input_with(/\A2\z/) do
        change_mode(:edit_reputation)
        internal_state[:reputation_name] = "friendly"
        send_no_prompt("[f:green]Enter new reputation value for \"Friendly\" >>")
      end

      parse_input_with(/\A3\z/) do
        change_mode(:edit_reputation)
        internal_state[:reputation_name] = "trusted"
        send_no_prompt("[f:green]Enter new reputation value for \"Trusted\" >>")
      end

      parse_input_with(/\A4\z/) do
        change_mode(:edit_reputation)
        internal_state[:reputation_name] = "exalted"
        send_no_prompt("[f:green]Enter new reputation value for \"Exalted\" >>")
      end

      parse_input_with(/\A5\z/) do
        change_mode(:edit_hostility)
        send_hostility_menu
      end

      parse_input_with(/\A6\z/) do
        change_input_state(:standard)
        send_room_description
      end

      # --- Private Helpers --------------------------------------------------

      private

      def editing_faction
        internal_state[:faction]
      end
    end
  end
end

Input::Manager.register_responder(:faction_builder, Input::Responder::FactionBuilder)