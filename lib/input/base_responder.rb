module Input
  module Responder
    class Base
      class << self
        @allow_blank_input = false

        def before_responder(*names)
          @before_responders ||= []
          @before_responders += names
        end

        def after_responder(*names)
          @after_responders ||= []
          @after_responders += names
        end

        def before_responders
          (@before_responders ||= [])
        end

        def after_responders
          (@after_responders ||= [])
        end

        def responders_for_mode(mode, &block)
          @current_mode = mode
          class_eval(&block)
          @current_mode = nil
        end

        def parse_input_with(*regexs, &block)
          regexs.each do |regex|
            responders(@current_mode) << [regex, block]
          end
        end

        def responders(mode)
          mode = :__default if mode.nil?
          (@responders ||= {})
          (@responders[mode] ||= [])
        end

        def allow_blank_input?
          @allow_blank_input
        end

        def allow_blank_input
          @allow_blank_input = true
        end
      end

      def initialize(connection)
        @connection = connection
      end

      def create_responder(klass)
        klass.new(connection)
      end

      def respond_to(input)
        current_mode = if connection.internal_state.kind_of?(Hash)
          connection.internal_state[:mode] || :__default
        else
          :__default
        end
        self.class.responders(current_mode).each do |(regex, block)|
          match_data = input.match(regex)
          if match_data
            self.class.before_responders.each { |method| return true if __send__(method) == false }
            input_args = match_data[1..match_data.length]
            instance_exec(*input_args, &block)
            self.class.after_responders.each { |method| __send__(method) }
            return true
          end
        end
        false
      end

      protected

      def render(*args)
        meth_name = args.last
        if meth_name.kind_of?(Hash)
          meth_name = :send_no_prompt
        else
          args.pop
        end
        view = Helpers::View.render(*args)
        __send__(meth_name, view)
      end

      def input_state
        connection.input_state
      end

      def change_mode(new_mode)
        internal_state[:mode] = new_mode
      end

      def clear_mode
        internal_state.delete(:mode)
      end

      def store_original_state(callback = nil)
        self.original_state = {
          input_state: input_state,
          internal_state: internal_state,
        }
        original_state[:callback] = callback if callback
      end

      def restore_original_state
        return unless original_state.present?
        change_input_state(original_state[:input_state])
        self.internal_state = original_state[:internal_state]
        original_state[:callback].call if original_state[:callback]
        self.original_state = nil
      end

      def original_state
        connection.original_state
      end

      def original_state=(value)
        connection.original_state = value
      end

      def logger
        Laeron.config.logger
      end

      def send_room_description(room = nil)
        room = current_room if room.nil?
        send_no_newline(room.display_text(player))
      end

      def player
        connection.player
      end

      def current_room
        connection.player.room
      end

      def change_input_state(new_state)
        connection.input_state = new_state
      end

      def internal_state
        connection.internal_state
      end

      def internal_state=(value)
        connection.internal_state = value
      end

      def send(text, opts = {})
        connection.send_text(text, opts)
      end

      def send_no_prompt(text)
        connection.send_text(text, prompt: false)
      end

      def send_no_newline(text)
        connection.send_text(text, newline: false)
      end

      def send_no_prompt_or_newline(text)
        connection.send_text(text, newline: false, prompt: false)
      end

      def send_unknown_input
        InputManager.unknown_input(connection)
      end

      def send_not_authorized
        connection.send_text("[f:red]You are not authorized to access this command!", prompt: false)
      end

      attr_reader :connection
    end
  end
end

# Use these comments for new InputResponders

  # --- Template Helpers -----------------------------------------------------
  # --- Helpers --------------------------------------------------------------
  # --- Responders -----------------------------------------------------------