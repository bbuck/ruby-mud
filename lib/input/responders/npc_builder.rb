module Input
  module Responder
    class NpcBuilder < Base
      # --- Template Helpers -----------------------------------------------------

      def send_npc_builder_menu
        menu = <<-MENU.strip_heredoc


          [f:white:b]+-----------------------------------------------------------------------------+
          |   [f:green]NPC Builder (v 1.0 by Brandon Buck)[f:white:b]                                       |
          +-----------------------------------------------------------------------------+

          [f:green]= Room ##{editing_npc.id} - [f:cyan:b]#{editing_npc.name}

          [f:white:b][1][f:green] Edit NPC Name
          [f:white:b][2][f:green] Edit NPC Description
          [f:white:b][3][f:green] Edit Script
          [f:white:b][4][f:green] Delete NPC

          [f:white:b][5][f:green] Exit Editor
          [f:white:b]
          +-----------------------------------------------------------------------------+

          [f:green]Enter Option >>
        MENU
        send_no_prompt(menu)
      end

      # --- Helpers --------------------------------------------------------------

      def editing_npc
        internal_state[:npc]
      end

      def edit_npc(npc)
        change_input_state(:npc_builder)
        self.internal_state = {npc: npc}
        player.update_attribute(:room, npc.room)
        send_npc_builder_menu
      end

      # --- Responders -----------------------------------------------------------

      responders_for_mode :enter_npc_name do
        parse_input_with(/(.+)/) do |name|
          clear_mode
          editing_npc.update_attributes(name: name)
          send_npc_builder_menu
        end
      end

      parse_input_with(/\A1\z/) do
        change_mode(:enter_npc_name)
        send_no_prompt("[f:green]Enter the NPC's name >>")
      end

      parse_input_with(/\A2\z/) do
        create_responder(Editor).open_editor(editing_npc, :description, allow_colors: true) do
          create_responder(NpcBuilder).send_npc_builder_menu
        end
      end

      parse_input_with(/\A3\z/) do
        create_responder(Editor).open_editor(editing_npc, :script, syntax: true) do
          create_responder(NpcBuilder).send_npc_builder_menu
        end
      end

      parse_input_with(/\A5\z/) do
        change_input_state(:standard)
        send_room_description
      end
    end
  end
end

Input::Manager.register_responder(:npc_builder, Input::Responder::NpcBuilder)
