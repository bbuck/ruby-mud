class Yell
  MAX_YELL_DIST = 5

  def initialize(message, room, rooms_visited = [], yell_dist = 0)
    if yell_dist <= MAX_YELL_DIST
      if !rooms_visited.include?(room.id)
        room.transmit(message)
        rooms_visited << room.id
      end
      EM.next_tick do
        Room::EXITS.each do |exit_name|
          if room.send(exit_name)
            Yell.new(message, room.send("#{exit_name}_room"), rooms_visited, yell_dist + 1)
          end
        end
      end
    end
  end
end