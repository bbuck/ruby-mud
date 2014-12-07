module Input
  module Responder
    class NpcBuilder < Base
      # --- Template Helpers -----------------------------------------------------

      def write_npc_builder_menu
        editing_npc.reload
        render("responder.npc_builder.main_menu", npc: editing_npc)
      end

      def write_set_room_commands
        render("responder.npc_builder.room_commands")
      end

      # --- Helpers --------------------------------------------------------------

      def editing_npc
        internal_state[:npc]
      end

      def edit_npc(npc, &block)
        store_original_state(block) if block_given?
        change_input_state(:npc_builder)
        self.internal_state = {npc: npc}
        player.update_attribute(:room, npc.room) if npc.room
        write_npc_builder_menu
      end

      # --- Responders -----------------------------------------------------------

      responders_for_mode :enter_npc_name do
        parse_input_with(/(.+)/) do |name|
          clear_mode
          editing_npc.update_attributes(name: name)
          write_npc_builder_menu
        end
      end

      responders_for_mode :set_room do
        parse_input_with(/\Aback\z/) do
          clear_mode
          write_npc_builder_menu
        end

        parse_input_with(/\Asearch (.+?)\z/) do |query|
          rooms = ::Room.name_like(query).limit(10)
          if rooms.count > 0
            room_str = rooms.map { |r| "[reset]##{r.id} - [f:white:b]#{r.display_name}" }.join("\n")
            write_without_prompt("\n#{room_str}\n")
          else
            write_without_prompt("[f:yellow:b]No rooms with names like \"#{query}\" were found.")
          end
        end

        parse_input_with(/\Aset #?(\d+)\z/) do |room_id|
          begin
            room = ::Room.find(room_id)
            editing_npc.update_attributes(room: room)
            clear_mode
            write_npc_builder_menu
          rescue ActiveRecord::RecordNotFound => e
            write_without_prompt("[f:yellow:b]No room with ID ##{room_id} exists, try using a real room!")
          end
        end
      end

      parse_input_with(/\A1\z/) do
        change_mode(:enter_npc_name)
        write_without_prompt("[f:green]Enter the NPC's name >>")
      end

      parse_input_with(/\A2\z/) do
        create_responder(Editor).open_editor(editing_npc, :description, allow_colors: true) do
          write_npc_builder_menu
        end
      end

      parse_input_with(/\A3\z/) do
        create_responder(Editor).open_editor(editing_npc, :script, syntax: true) do
          write_npc_builder_menu
        end
      end

      parse_input_with(/\A6\z/) do
        change_mode(:set_room)
        write_set_room_commands
      end

      parse_input_with(/\A7\z/) do
        change_input_state(:standard)
        write_room_description
      end
    end
  end
end

Input::Manager.register_responder(:npc_builder, Input::Responder::NpcBuilder)
