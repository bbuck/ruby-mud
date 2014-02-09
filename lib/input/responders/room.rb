InputManager.respond_to :standard do
  parse_input_with /l|look/ do |conn|
    conn.send_text(conn.player.room.display_text(conn.player))
  end

  # TODO: Northwest, Northeast

  parse_input_with /n|north/ do |conn|
    if conn.player.room.north
      cur_room, new_room = conn.player.room, conn.player.room.north_room
      new_room.player_enters(conn.player, :north)
      conn.player.update_attributes(room: new_room)
      conn.send_text(new_room.display_text(conn.player))
      cur_room.player_leaves(conn.player, :north)
    else
      conn.send_text("There is not an exit to the north!")
    end
  end

  # TODO: Southwest, Southeast

  parse_input_with /s|south/ do |conn|
    if conn.player.room.south
      cur_room, new_room = conn.player.room, conn.player.room.south_room
      new_room.player_enters(conn.player, :south)
      conn.player.update_attributes(room: new_room)
      conn.send_text(new_room.display_text(conn.player))
      cur_room.player_leaves(conn.player, :south)
    else
      conn.send_text("There is not an exit to the south!")
    end
  end
end