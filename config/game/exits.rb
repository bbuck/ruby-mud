Helpers::Exit.define_exits do
  exit :north, :south, "the north", :n
  exit :south, :north, "the south", :s
  exit :west, :east, "the west", :w
  exit :east, :west, "the east", :e
  exit :northwest, :southeast, "the northwest", :nw
  exit :northeast, :southwest, "the northeast", :ne
  exit :southwest, :northeast, "the southwest", :sw
  exit :southeast, :northwest, "the southeast", :se
  exit :up, :down, "above", :u
  exit :down, :up, "below", :d
end