# ### InputManager
#
#
class InputManager
  UNKNOWN_INPUT_RESPONSES = [
    "I'm sorry, did you type something?",
    "Come again? Remember I only understand English commands.",
    "Try \"help\" because you obviously need it.",
    "You lied to me when you told me this was a command!",
    "YOU CAN'T DO THAT!",
    "Sorry I don't know how to help in this situation.",
    "A funny command that I can't process has just been input. Continue, and I'll forget this ever happened.",
    "You can't do that in horizontal mode!",
    "Invalid Command! Feel ashamed for yourself and try again.",
    "Of all the commands available, you picked the wrong one.",
    "You are a charlaton.",
    "I beg your pardon?!",
    "Not tonight, I have a headache.",
    "You must be joking!",
    "Your guess is probably much better than mine.",
    "You have not gotten any Error messages recently, so here is a random one just so you know we haven't started caring.",
    "User Error! Replace User and continue.",
    "You will receive another error message in the future.",
    "Error Unknown: The error is unkown because the guy who wrote this part of the code quit a while back and he was like, really really smart and the rest of us are not really sure how this works or what to do.",
    "Error: The operation completed successfully.",
    "Programmer goofed! You should never see this message.",
    "Sorry I already gave what help I could.",
    "Maybe you should ask a human?",
    "No message, no subject. Hope that's okay.",
    "Identity Problems, eh?",
    "Bad Craziness.",
    "This is no game for mere mortals.",
    "Good afternoon gentlemen, I'm a HAL 9000 computer.",
    "Liar, Liar! Pants on Fire!",
    "Y vsn kypr xii@"
  ]

  class << self
    def responders
      @@responders ||= {}
    end

    # ---- Begin DSL ----
    def current_responder_state(state = nil)
      if state.nil?
        @current_state
      else
        @current_state = (state == false ? nil : state)
      end
    end

    def respond_to_state_with(state, regex, &block)
      return unless block_given?
      if regex.is_a?(Array)
        regex.each do |rx|
          (responders[state] ||= []) << [rx, block]
        end
      else
        (responders[state] ||= []) << [regex, block]
      end
    end

    def respond_to(state, &block)
      current_responder_state(state)
      class_eval(&block)
      current_responder_state(false)
    end

    def parse_input_with(regex, &block)
      return unless current_responder_state
      respond_to_state_with(current_responder_state, regex, &block)
    end
    # ---- End DSL ----

    def process(input, connection)
      input.gsub!(/\r\n/, "")
      state = connection.input_state
      if responders.has_key?(state)
        responders[state].each do |(regex, block)|
          match_data = input.match(regex)
          if match_data
            input_args = match_data[1..match_data.length]
            return block.call(connection, *input_args)
          end
        end
      end
      unknown_input(connection)
    end

    def unknown_input(connection)
      connection.send_text("[f:yellow:b]#{UNKNOWN_INPUT_RESPONSES.sample}")
    end
  end
end

Laeron.require_all(Laeron.root.join("lib", "input", "responders", "**", "*"))