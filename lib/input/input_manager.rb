# ### InputManager
#
#
class InputManager
  UNKNOWN_INPUT_RESPONSES = [
    "I'm sorry, but it doesn't appear that you entered a valid command. Type \"help\" if you need assistance."
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
      (responders[state] ||= [])  << [regex, block]
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
      connection.send_text(UNKNOWN_INPUT_RESPONSES.sample)
    end
  end
end

Laeron.require_all(Laeron.root.join("lib", "input", "responders", "**", "*"))