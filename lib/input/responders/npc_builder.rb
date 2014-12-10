module Input
  module Responder
    class NpcBuilder < Base
      # --- Template Helpers --------------------------------------------------

      def write_npc_builder_menu
        editing_npc.reload
        render("responder.npc_builder.main_menu", npc: editing_npc, room_count: editing_npc.spawned_npcs.in_room.select("DISTINCT room_id").count)
      end

      def write_set_room_commands
        render("responder.npc_builder.room_commands", room_count: editing_npc.spawned_npcs.in_room.select("DISTINCT room_id").count)
      end

      # --- Helpers -----------------------------------------------------------

      def editing_npc
        internal_state[:npc]
      end

      def edit_npc(npc, &block)
        store_original_state(&wblock) if block_given?
        change_input_state(:npc_builder)
        self.internal_state = {npc: npc}
        player.update_attribute(:room, npc.room) if npc.room
        write_npc_builder_menu
      end

      def exit_npc_builder
        if stored_original_state?
          restore_original_state
        else
          change_input_state(:standard)
          write_room_description
        end
      end

      # --- Responders --------------------------------------------------------

      responders_for_mode :enter_npc_name do
        parse_input_with(/(.+)/) do |name|
          clear_mode
          editing_npc.update_attributes(name: name)
          write_npc_builder_menu
        end
      end

      responders_for_mode :add_to_rooms do
        parse_input_with(/\Aback\z/) do
          clear_mode
          write_npc_builder_menu
        end

        parse_input_with(/\Alist\z/) do
          rooms = SpawnedNPCs.with_base_npc(editing_npc).map(&:room)
          if rooms.length > 0
            room_str = rooms.map { |r| "[reset]#{r.id} - [f:white:b]#{r.display_name}" }
            write_without_prompt("\n#{room_str}\n")
          else
            write_without_prompt("[f:green]This NPC hasn't been added to any rooms yet, add it to one!")
          end
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

        parse_input_with(/\Aadd #?(\d+)\z/) do |room_id|
          begin
            editing_npc.spawn(::Room.find(room_id))
            write_set_room_commands
          rescue ActiveRecord::RecordNotFound => e
            write_without_prompt("[f:yellow:b]No room with ID ##{room_id} exists, try using a real room!")
          end
        end
      end

      responders_for_mode :set_timer do
        parse_input_with(/\Anone\z/) do
          if internal_state[:timer] == :update
            editing_npc.update_attributes(update_timer: nil)
          elsif internal_state[:timer] == :respawn
            editing_npc.update_attributes(respawn_timer: nil)
          end
          clear_mode
          internal_state.delete(:timer)
          write_npc_builder_menu
        end

        parse_input_with(/\A(.+?)\z/) do |time|
          if internal_state[:timer] == :update
            editing_npc.update_attributes(update_timer: time)
          elsif internal_state[:timer] == :respawn
            # TODO: Do things if they're dead
            editing_npc.update_attributes(respawn_timer: time)
          end
          clear_mode
          internal_state.delete(:timer)
          write_npc_builder_menu
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

      parse_input_with(/\A4\z/) do
        internal_state[:timer] = :update
        change_mode(:set_timer)
        write_without_prompt("[f:green]Enter a new update time interval (1 minute is the minimum inteval) >>")
      end

      parse_input_with(/\A5\z/) do
        internal_state[:timer] = :respawn
        change_mode(:set_timer)
        write_without_prompt("[f:green]Enter a new respawn time interval >>")
      end

      parse_input_with(/\A6\z/) do
        change_mode(:add_to_rooms)
        write_set_room_commands
      end

      parse_input_with(/\A7\z/) do
        exit_npc_builder
      end
    end
  end
end

Input::Manager.register_responder(:npc_builder, Input::Responder::NpcBuilder)
