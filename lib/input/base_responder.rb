module Input
  module Responder
    class Base
      include ActiveSupport::Callbacks
      define_callbacks :responder, terminator: ->(target, result) { result == false }

      # Class Methods

      class << self
        @allow_blank_input = false

        def before_responder(name, options = {}, &block)
          set_callback_helper(:before, :responder, name, options, &block)
        end

        def after_responder(name, options = {}, &block)
          set_callback_helper(:after, :responder, name, options, &block)
        end

        def around_responder(name, options = {}, &block)
          set_callback_helper(:around, :responder, name, options, &block)
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

        private

        def set_callback_helper(before_or_after, callback, name, options, &block)
          set_callback(callback, before_or_after, name, options, &block)
        end
      end

      # Instance methods

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
          if match_data = input.match(regex)
            run_callbacks :responder do
              input_args = match_data[1..match_data.length]
              instance_exec(*input_args, &block)
            end
            return true
          end
        end
        false
      end

      protected

      def render(*args)
        meth_name = args.last
        unless meth_name.kind_of?(Symbol)
          meth_name = :write_without_prompt
        else
          args.pop
        end
        view = Helpers::View.render(*args)
        send(meth_name, view)
      end

      def input_state
        connection.input_state
      end

      def change_mode(new_mode)
        self.internal_state = {} if internal_state.blank?
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

      def stored_original_state?
        original_state.present?
      end

      def logger
        Laeron.config.logger
      end

      def write_room_description(room = nil)
        room = current_room if room.nil?
        write_without_newline(room.display_text(player))
      end

      def player
        connection.player
      end

      def current_room
        connection.player.room
      end

      def change_input_state(new_state)
        connection.input_state = new_state
        connection.internal_state = nil
      end

      def internal_state
        connection.internal_state
      end

      def internal_state=(value)
        connection.internal_state = value
      end

      def write(text, opts = {})
        connection.write(text, opts)
      end

      def write_without_prompt(text)
        connection.write(text, prompt: false)
      end

      def write_without_newline(text)
        connection.write(text, newline: false)
      end

      def write_without_prompt_or_newline(text)
        connection.write(text, newline: false, prompt: false)
      end

      def write_unknown_input
        InputManager.unknown_input(connection)
      end

      def write_not_authorized
        write_without_prompt("[f:yellow:b]You are not authorized to access this command!")
      end

      attr_reader :connection
    end
  end
end

# Use these comments for new InputResponders

  # --- Template Helpers -----------------------------------------------------
  # --- Helpers --------------------------------------------------------------
  # --- Responders -----------------------------------------------------------