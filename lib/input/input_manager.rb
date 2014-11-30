module Input
  class Manager
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
      def register_responder(for_state, responder_cls)
        (responders[for_state] ||= []) << responder_cls
      end

      def process(input, connection)
        input = input.gsub(/\r\n/, "").rstrip
        blank_input = input.length == 0
        state = connection.input_state
        if responders.has_key?(state)
          responders[state].each do |responder_cls|
            if blank_input
              next unless responder_cls.allow_blank_input?
            end
            responder = responder_cls.new(connection)
            if responder.respond_to(input)
              return
            end
          end
        end
        unknown_input(connection) unless blank_input
      end

      def unknown_input(connection)
        connection.send_text("[f:yellow:b]#{UNKNOWN_INPUT_RESPONSES.sample}", prompt: false)
      end

      private

      def responders
        @responders ||= {}
      end
    end
  end
end

require "input/base_responder"
Laeron.require_all(Laeron.root.join("lib", "input", "responders", "**", "*"))