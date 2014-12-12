module Helpers
  class Exit
    class << self
      def define_exits(&block)
        @exits ||= []
        @exits_inverse ||= {}
        @exits_proper ||= {}
        @exits_expanded ||= {}
        class_eval(&block)
      end

      def each(&block)
        return unless block_given?
        @exits.each do |exit_name|
          yield(exit_name)
        end
      end

      def map(&block)
        return unless block_given?
        @exits.map do |exit_name|
          yield(exit_name)
        end
      end

      def valid?(exit)
        exit = exit.to_sym
        @exits.include?(exit.to_sym)
      end

      def inverse(exit)
        @exits_inverse[exit.to_sym]
      end

      def proper(exit)
        @exits_proper[exit.to_sym]
      end

      def expand(exit)
        exit = exit.to_sym
        if @exits_expanded.has_key?(exit)
          @exits_expanded[exit]
        else
          exit
        end
      end

      private

      def exit(name, inverse, proper, shortcut)
        @exits << name
        @exits_inverse[name] = inverse
        @exits_proper[name] = proper
        @exits_expanded[shortcut] = name
      end
    end
  end
end