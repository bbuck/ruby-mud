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
      exit = exit.to_sym
      EXITS.include?(exit)
    end

    def inverse(exit)
      exit = exit.to_sym
      EXITS_INVERSE[exit]
    end

    def proper(exit)
      exit = exit.to_sym
      EXITS_PROPER[exit]
    end

    def expand(exit)
      exit = exit.to_sym
      if EXITS_EXPANDED.has_key?(exit)
        EXITS_EXPANDED[exit]
      else
        exit
      end
    end
  end
end