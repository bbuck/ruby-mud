module Input
  module Responder
    class Player < Base
      # ---- Responders -------------------------------------------------------

      parse_input_with(/\Aedit desc(?:ription)?\z/) do
        create_responder(Editor).open_editor(player, :description, allow_colors: true) do |conn|
          write_no_prompt("[f:green]You finished editing your description.")
        end
      end
    end
  end
end

Input::Manager.register_responder(:standard, Input::Responder::Player)