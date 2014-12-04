module Game
  class Yell
    MAX_YELL_DIST = 5

    def initialize(message, room, rooms_visited = [], yell_dist = 0)
      if yell_dist <= MAX_YELL_DIST
        if !rooms_visited.include?(room.id)
          room.transmit(message)
          rooms_visited << room.id
        end
        EM.next_tick do
          room.exit_array.each do |exit_name|
            yell_difficulty = room.exit_open(exit_name) ? 1 : 3
            Yell.new(message, room.send(exit_name), rooms_visited, yell_dist + yell_difficulty)
          end
        end
      end
    end
  end
end