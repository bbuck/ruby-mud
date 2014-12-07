module Input
  module Responder
    class Login < Base
      VALID_USERNAME_RX = /\A[a-z]{2}[a-z'-]{0,17}[a-z]\z/i
      INVALID_NAME_SEQUENCE_RX = /'-|''|-'/

      # --- Helpers --------------------------------------------------------------

      def valid_username?(username)
        if username =~ VALID_USERNAME_RX
          if username.scan(/'/).count <= 2 && username.scan(/-/).count <= 1
            username.scan(INVALID_NAME_SEQUENCE_RX).count == 0
          else
            false
          end
        else
          false
        end
      end

      def valid_password?(password)
        password.length >= 8 && password.length <= 50
      end

      def write_enter_password_text(username)
        write_without_prompt_or_newline("\n[f:yellow:b]Please enter a password for \"[f:cyan:b]#{username}[f:yellow:b]\":\n")
        write(Telnet::IAC_DONT_ECHO, raw: true)
      end

      def write_initial_greeting
        write_without_prompt("Welcome to Laeron, please enter your character's name or type \"[f:white:b]new[reset]\"")
      end

      def connect_player(new_player)
        connection.player = new_player
        player.room.player_appears(player)
        ::Player.connect(player, connection)
        logger.info("Player #{player.username} has connected.")
        change_input_state(:standard)
      end

      # --- Responders -----------------------------------------------------------

      responders_for_mode :create_name do
        parse_input_with(/(.+)/) do |username|
          username = username.capitalize
          if valid_username?(username)
            if ::Player.with_username(username).count > 0
              write_without_prompt("\nWe're sorry but a player has already taken the name \"[f:white:b]#{username}[f:yellow:b].\" Please choose another name.")
            else
              self.internal_state = {mode: :create_password, username: username}
              write_enter_password_text(internal_state[:username])
            end
          else
            write_without_prompt_or_newline(Helpers::View.render("responder.login.username_requirements"))
          end
        end
      end

      responders_for_mode :confirm_name do
        parse_input_with(/\A(yes|y|no|n)\Z/i) do |input|
          if input =~ /y/i
            change_mode(:create_password)
            write_enter_password_text(internal_state[:username])
          else
            self.internal_state = nil
            write_initial_greeting
          end
        end
      end

      responders_for_mode :create_password do
        parse_input_with(/(.+)/) do |password|
          if valid_password?(password)
            write_without_prompt("Please reenter your password:#{ANSI::HIDDEN}")
            change_mode(:confirm_password)
            internal_state[:password] = password
          else
            write_without_prompt("\n[f:red]That password is not valid.")
            write_without_prompt(Helpers::View.render("responder.login.password_requirements"))
          end
        end
      end

      responders_for_mode :confirm_password do
        parse_input_with(/(.+)/) do |password|
          if password == internal_state[:password]
            # TODO: Fix origin room (should be from DB)
            new_player = ::Player.new(username: internal_state[:username], password: password, room_id: 1)
            if new_player.save
              logger.info("#{new_player.username} has been created.")
              connect_player(new_player)
              write_without_prompt("\nYou have successfully joined the world of Laeron.")
              write_room_description
            else
              logger.error("Failed to create a player")
              self.internal_state = nil
              write_without_prompt("[f:red:b]There was an error creating your character, please try again.")
              write_initial_greeting
            end
          else
            write_without_prompt("\n[f:red]The passwords do not match!")
            write_enter_password_text(internal_state[:username])
            change_mode(:create_password)
            internal_state.delete(:password)
          end
        end
      end

      responders_for_mode :enter_password do
        parse_input_with(/(.+)/) do |password|
          if internal_state[:player].password == password
            connect_player(internal_state[:player])
            write_room_description
          else
            write_without_prompt("[f:red]That password is incorrect!")
            connection.quit
          end
        end
      end

      parse_input_with(/\Anew\z/) do
        write_without_prompt(Helpers::View.render("responder.login.username_rules"))
        write_without_prompt("[f:white:b]Please enter a name for your character that complies with the rules above:")
        self.internal_state = {mode: :create_name}
      end

      parse_input_with(/(.+)/) do |username|
        players = ::Player.with_username(username)
        if players.count == 0
          if valid_username?(username)
            write_without_prompt(Helpers::View.render("responder.login.username_rules"))
            write_without_prompt("Did you enter the name \"[f:white:b]#{username}[reset]\" correctly and does this name comply with the rules above [f:green:b](y/n)[reset]?")
            self.internal_state = {mode: :confirm_name, username: username.capitalize}
          else
            write_without_prompt("[f:yellow:b]The name \"[f:white:b]#{username.capitalize}[f:yellow:b]\" is not valid, please review the username requirements.")
            write_without_prompt_or_newline(Helpers::View.render("responder.login.username_requirements"))
          end
        else
          self.internal_state = {mode: :enter_password, player: players.first}
          write_without_prompt_or_newline("\nEnter the password for \"[f:white:b]#{username.capitalize}[reset]\"\n#{ANSI::HIDDEN}")
        end
      end
    end
  end
end

Input::Manager.register_responder(:login, Input::Responder::Login)