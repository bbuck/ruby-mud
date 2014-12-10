module Input
  module Responder
    class BuilderCommands < Base
      # --- Templates Helpers ----------------------------------------------------

      def write_room_info(room = current_room)
        render("responder.build_commands.room_info", {room: room}, :write)
      end

      # --- Helpers --------------------------------------------------------------

      def create_and_edit_room(room_name)
        room = ::Room.create(name: room_name, description: Laeron.config.room.default_description, creator: player)
        create_responder(RoomBuilder).edit_room(room)
      end

      # --- Room Handlers --------------------------------------------------------

      before_responder :player_can_build?

      parse_input_with(/\A@room info #?(\d+)\z/) do |room_id|
        begin
          room = ::Room.find(room_id)
          write_room_info(room)
        rescue ActiveRecord::RecordNotFound => e
          write("[f:yellow:b]There is no room with the id ##{room_id}")
        end
      end

      parse_input_with(/\A@room info\z/) do
        write_room_info
      end

      parse_input_with(/\A@room search (.*?)\z/) do |query|
        rooms = ::Room.name_like(query).limit(10)
        if rooms.count > 0
          lines = rooms.map do |room|
            "[f:green]##{room.id} - [f:white:b]#{room.name}"
          end
          str = "\n" + lines.join("\n") + "\n"
          write_without_prompt(str)
        else
          write_without_prompt("[f:yellow:b]No rooms were found matching \"#{query}\"")
        end
      end

      parse_input_with(/\A@dig (.+)\z/) do |room_name|
        create_and_edit_room(room_name)
      end

      parse_input_with(/\A@dig\z/) do
        create_and_edit_room(Laeron.config.room.default_name)
      end

      parse_input_with(/\A@edit room #?(\d+)\z/) do |room_id|
        begin
          room = ::Room.find(room_id)
          create_responder(RoomBuilder).edit_room(room)
        rescue ActiveRecord::RecordNotFound => e
          write("[f:yellow:b]There is no room with the id ##{room_id}")
        end
      end

      parse_input_with(/\A@edit room\z/) do
        create_responder(RoomBuilder).edit_room(current_room)
      end

      # --- NPC Handlers -----------------------------------------------------

      parse_input_with(/\A@npc search (.+?)\z/) do |query|
        npcs = ::NPC.name_like(query).limit(10)
        if npcs.count > 0
          npc_str = npcs.map { |n| "#[f:white:b]#{n.id}[reset] - #{n.display_name}[reset]" }
        else
          npc_str = ["[f:green]No NPCs found matching \"#{query}\" were found, you might need to create it!"]
        end
        render("responder.npc_builder.npc_list", npc_string: npc_str.join("\n"), query: query)
      end

      parse_input_with(/\A@edit npc #?(\d+)\z/) do |id|
        begin
          npc = ::NPC.find(id.to_i)
          create_responder(NpcBuilder).edit_npc(npc)
        rescue ActiveRecord::RecordNotFound => e
          write_without_prompt("[f:yellow:b]The NPC with id \"#{id}\" does not exist!")
        end
      end

      parse_input_with(/\A@npc create (.+?)\z/) do |name|
        npc = ::NPC.create(name: name, creator: player)
        create_responder(NpcBuilder).edit_npc(npc)
      end

      # --- Faction Handlers -------------------------------------------------

      parse_input_with(/\A@faction create (.+)\z/) do |name|
        faction = ::Faction.create(name: name)
        create_responder(FactionBuilder).edit_faction(faction)
      end

      parse_input_with(/\A@faction search (.+?)\z/) do |query|
        factions = ::Faction.name_like(query).limit(10)
        if factions.count > 0
          faction_str = factions.map { |f| "##{f.id} - #{f.name}" }
        else
          faction_str = ["[f:green]No factions matching \"#{query}\" were found, you might need to create it."]
        end
        render("responder.build_commands.faction_list", faction_str: faction_str.join("\n"), query: query)
      end

      parse_input_with(/\A@edit faction #?(\d+)\z/) do |id|
        begin
          faction = ::Faction.find(id)
          create_responder(FactionBuilder).edit_faction(faction)
        rescue ActiveRecord::RecordNotFound => e
          write_without_prompt("[f:yellow:b]The faction with id \"#{id}\" does not exist")
        end
      end

      private

      def player_can_build?
        unless player.can_build?
          write_not_authorized
          false
        end
      end
    end
  end
end

Input::Manager.register_responder(:standard, Input::Responder::BuilderCommands)