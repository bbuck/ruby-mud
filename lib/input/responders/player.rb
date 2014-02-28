class PlayerResponder < InputResponder
  parse_input_with(/\Aedit desc(?:ription)?\z/) do
    EditorResponder.new(connection).open_editor(player, :description, allow_colors: true) do |conn|
      send_no_prompt("[f:green]You finished editing your description.")
    end
  end
end

InputManager.add_responder(:standard, PlayerResponder)