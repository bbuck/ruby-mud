module Helpers
  class Exit
    # EXITS = [:north, :south, :east, :west, :northwest, :northeast, :southwest,
    #          :southeast, :up, :down]

    # EXITS_INVERSE = { north: :south, south: :north, east: :west, west: :east,
    #                   northwest: :southeast, northeast: :southwest,
    #                   southeast: :northwest, southwest: :northeast, up: :down,
    #                   down: :up }

    # EXITS_PROPER = { north: "the north", south: "the south", east: "the east",
    #                  west: "the west", northwest: "the northwest",
    #                  northeast: "the northeast", southwest: "the southwest",
    #                  southeast: "the southeast", up: "above", down: "below" }

    # EXITS_EXPANDED = { n: :north, s: :south, e: :east, w: :west, nw: :northwest,
    #                    ne: :northeast, sw: :southwest, se: :southeast, u: :up,
    #                    d: :down }

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