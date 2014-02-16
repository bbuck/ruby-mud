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
    conn.send_text(text, newline: false, prompt: false)
    conn.internal_state = :create_name
  end

  parse_input_with /\A(y|yes|n|no)\Z/i do |conn, input|
    if conn.internal_state.is_a?(Hash) && conn.internal_state[:confirm_name]
      if input =~ /y|yes/i
        conn.internal_state = {new_name: conn.internal_state[:confirm_name]}
        conn.send_text("[f:white:b]Please enter a password for your character:\n#{ANSI::hidden}", newline: false, prompt: false)
      else
        conn.internal_state = nil
        conn.send_text("Welcome to the Laeron, please enter your character's name or type \"new\"", prompt: false)
      end
    end
  end

  parse_input_with /(.+)/i do |conn, input|
    # --- Creating a name ---
    if conn.internal_state == :create_name
      if Player.with_username(input).count > 0 #Player.where("lower(username) = ?", input.downcase).count > 0
        conn.send_text("\nWe're sorry but a player has already taken the name \"[f:white:b]#{name.capitalize}[f:yellow:b].\" Please choose another name.", prompt: false)
      else
        conn.internal_state = {new_name: input.capitalize}
        conn.send_text("\nPlease enter a password for \"[f:cyan:b]#{input.capitalize}\":\n#{ANSI::hidden}", newline: false, prompt: false)
      end
    elsif conn.internal_state.is_a?(Hash)

      # --- Confirming Password ---
      if conn.internal_state.has_key?(:confirm_password)
        if input == conn.internal_state[:confirm_password]
          # TODO: Fix origin room (should be from DB)
          player = Player.new(username: conn.internal_state[:new_name], password: input, room_id: 1)
          if player.save
            conn.player = player
            player.room.player_appears(player)
            Player.connect(player, conn)
            conn.input_state = :standard
            conn.send_text("\nYou have successfully joined the world of Laeron.", prompt: false)
            conn.send_text(player.room.display_text(player), newline: false)
            Laeron.config.logger.info("Player #{player.username} has been created and connected.", prompt: false)
          else
            Laeron.config.logger.error("Failed to create a player")
            conn.internal_state = nil
            conn.send_text("[f:red:b]There was an error creating your character, please try again.", prompt: false)
          end
        else
          conn.send_text("\nThe passwords do not match, please give \"[f:white:b]#{conn.internal_state[:new_name]}[f:yellow:b]\" a password:\n#{ANSI::hidden}", newline: false, prompt: false)
          conn.internal_state.delete(:confirm_password)
        end

      # --- Reenter your Password ---
      elsif conn.internal_state.has_key?(:new_name)
        conn.send_text("Please reenter your password:#{ANSI::hidden}", prompt: false)
        conn.internal_state[:confirm_password] = input
      end
    elsif conn.player.nil?

      # --- Testing Password ---
      if conn.internal_state.is_a?(Player)
        if conn.internal_state.password == input
          conn.player = conn.internal_state
          conn.player.room.player_appears(conn.player)
          Player.connect(conn.player, conn)
          conn.input_state = :standard
          Laeron.config.logger.info("Player #{conn.player.username} has connected.")
          conn.send_text("\nYou have successfully connected to Laeron!", prompt: false)
          conn.send_text(conn.player.room.display_text(conn.player), newline: false)
        else
          conn.send_text("\n[f:red:b]The password entered was not correct.", prompt: false)
          conn.internal_state = nil
        end

      # --- Unknown Username ---
      elsif Player.with_username(input).count == 0
        text = <<-TEXT

I don't recognize "[f:white:b]#{input}[reset]" you must be new.

Learon is a fantasy themed Roleplaying game, therefore there are a few rules that your Character name must conform to.

[f:green:b]1. We do not accept Modern names such as Brandon, John, Jennifer, or Amber.
2. Names that are part of other stories such as those out of books, games, or movies are not allowed.
3. Names of Mythological characters or Gods are not allowed.[reset]

Try to choose a name that is unique for your character and unique to the world.

Did you enter the name "[f:white:b]#{input}[reset]" correctly and does this name comply with the rules above [f:green:b](y/n)[reset]?
        TEXT
        conn.send_text(text, newline: false, prompt: false)
        conn.internal_state = {confirm_name: input.capitalize}

      # --- Found user, enter password
      else
        conn.internal_state = Player.with_username(input).first
        conn.send_text("\nEnter the password for \"[f:white:b]#{input.capitalize}[reset]\"\n#{ANSI::hidden}", newline: false, prompt: false)
      end
    end
  end
end