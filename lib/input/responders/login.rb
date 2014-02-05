InputManager.respond_to :login do
  parse_input_with /new/i do |conn|
    text = <<-TEXT

Learon is a fantasy themed Roleplaying game, therefore there are a few rules that your Character name must conform to.

[f:green:b]1. We do not accept Modern names such as Brandon, John, Jennifer, or Amber.
2. Names that are part of other stories such as those out of books, games, or movies are not allowed.
3. Names of Mythological characters or Gods are not allowed.[reset]

Try to choose a name that is unique for your character and unique to the world.

[f:white:b]Please enter a name for your character that complies with the rules above:
    TEXT
    conn.send_text(text, newline: false)
    conn.internal_state = :create_name
  end

  parse_input_with /\A(y|yes|n|no)\Z/i do |conn, input|
    if conn.internal_state.is_a?(Hash) && conn.internal_state[:confirm_name]
      if input =~ /y|yes/i
        conn.internal_state = {new_name: conn.internal_state[:confirm_name]}
        conn.send_text("[f:white:b]Please enter a password for your character:\n#{ANSI::hidden}", newline: false)
      end
    end
  end

  parse_input_with /(.+)/i do |conn, input|
    if conn.internal_state == :create_name
      if Player.where(username: input).count > 0
        conn.send_text("[f:yellow:b]We're sorry but a player has already taken the name \"[f:white:b]#{name.capitalize}[f:yellow:b].\" Please choose another name.")
      else
        conn.internal_state = {new_name: input.capitalize}
        conn.send_text("\n[f:white:b]Please enter a password for \"[f:cyan:b]#{input.capitalize}\"[f:white:b]:\n#{ANSI::hidden}", newline: false)
      end
    elsif conn.internal_state.is_a?(Hash)
      if conn.internal_state.has_key?(:confirm_password)
        if input == conn.internal_state[:confirm_password]
          player = Player.new(username: conn.internal_state[:new_name], password: input)
          if player.save
            conn.player = player
            Player.connect(player, conn)
            conn.input_state = :standard
            Laeron.config.logger.info("Player #{player.username} has been created and connected.")
          else
            Laeron.config.logger.error("Failed to create a player")
            conn.internal_state = nil
            conn.send_text("[f:red:b]There was an error creating your character, please try again.")
          end
        else
          conn.send_text("[f:yellow:b]The passwords do not match, please give \"[f:white:b]#{conn.internal_state[:new_name]}[f:yellow:b]\" a password:\n#{ANSI::hidden}", newline: false)
          conn.internal_state.delete(:confirm_password)
        end
      elsif conn.internal_state.has_key?(:new_name)
        conn.send_text("[f:yellow:b]Please reenter your password:#{ANSI::hidden}")
        conn.internal_state[:confirm_password] = input
      end
    elsif conn.player.nil?
      if conn.internal_state.is_a?(Player)
        if conn.internal_state.password == input
          conn.player = conn.internal_state
          Player.connect(player, conn)
          conn.input_state = :standard
        else
          conn.send_text("[f:red:b]The password entered was not correct.")
          conn.internal_state = nil
        end
      elsif Player.where(username: input).count == 0
        text = <<-TEXT

I don't recognize "[f:white:b]#{input}[reset]" you must be new.

Learon is a fantasy themed Roleplaying game, therefore there are a few rules that your Character name must conform to.

[f:green:b]1. We do not accept Modern names such as Brandon, John, Jennifer, or Amber.
2. Names that are part of other stories such as those out of books, games, or movies are not allowed.
3. Names of Mythological characters or Gods are not allowed.[reset]

Try to choose a name that is unique for your character and unique to the world.

Did you enter the name "[f:white:b]#{input}[reset]" correctly and does this name comply with the rules above [f:green:b](y/n)[reset]?
        TEXT
        conn.send_text(text, newline: false)
        conn.internal_state = {confirm_name: input.capitalize}
      else
        conn.internal_state = Player.where(username: input).first
        conn.send_text("[f:yellow:b]Enter your password:\n#{ANSI::hidden}", newline: false)
      end
    end
  end
end