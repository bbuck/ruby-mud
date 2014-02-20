module ExitHelpers
  EXITS = [:north, :south, :east, :west, :northwest, :northeast, :southwest,
           :southeast, :up, :down]

  EXITS_INVERSE = { north: :south, south: :north, east: :west, west: :east,
                    northwest: :southeast, northeast: :southwest,
                    southeast: :northwest, southwest: :northeast, up: :down,
                    down: :up }

  EXITS_PROPER = { north: "the north", south: "the south", east: "the east",
                   west: "the west", northwest: "the northwest",
                   northeast: "the northeast", southwest: "the southwest",
                   southeast: "the southeast", up: "above", down: "below" }

  EXITS_EXPANDED = { n: :north, s: :south, e: :east, w: :west, nw: :northwest,
                     ne: :northeast, sw: :southwest, se: :southeast, u: :up,
                     d: :down }

  class << self
    def each_exit(&block)
      return unless block_given?
      EXITS.each do |exit_name|
        yield(exit_name)
      end
    end

    def map_exits(&block)
      return unless block_given?
      EXITS.map do |exit_name|
        yield(exit_name)
      end
    end

    def valid_exit?(exit)
      EXITS.include?(exit)
    end

    def inverse(exit)
      EXITS_INVERSE[exit]
    end

    def proper(exit)
      EXITS_PROPER[exit]
    end

    def expand(exit)
      EXITS_EXPANDED[exit]
    end
  end
end