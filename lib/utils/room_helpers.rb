module RoomHelpers
  class << self
    def check_all_doors_and_locks
      Laeron.config.logger.debug("Starting a door/lock check.")
      now = Time.now
      Room.all.find_each(batch_size: 500) do |room|
        room.exits.each do |name, details|
          next unless details[:door].present?
          # Check lock first, it closes the door as well
          if details[:lock].present? && details[:lock][:unlocked] &&
             details[:lock][:lock_at].present? && details[:lock][:lock_at] < now
            room.close_exit(name)
            room.lock_exit(name)
            room.transmit("[f:green]A door closes and locks.")
          end
          if details[:door][:open] && details[:door][:close_at].present? && details[:door][:close_at] < now
            room.close_exit(name)
            room.transmit("[f:green]A door closes.")
          end
        end
      end
    end
  end
end