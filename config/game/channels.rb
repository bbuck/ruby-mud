Game::ChannelFormatter.create_formats do
  register_format :say_from, "[f:cyan:b]You say, \"%M\""
  register_format :say_to, "[f:cyan:b]%N says, \"%M\""
  register_format :yell, "[f:red:b]%N yells, \"%M\""
  register_format :xpost, "[f:yellow]%M"
  register_format :post, "[f:yellow]%N %M"
  register_format :ooc, "[OOC] %N: %M"
  register_format :general, "[f:white:b]([f:cyan]GENERAL[f:white:b]) [f:green]%N [f:white:b]- [reset]%M"
  register_format :trade, "[f:white:b]([f:blue]TRADE[f:white:b]) [f:green]%N [f:white:b]- [reset]%M"
  register_format :newbie, "[f:white:b]([f:green]NEWBIE[f:white:b]) [f:green]%N [f:white:b]- [reset]%M"
  register_format :tell_to, "[f:magenta]%N tells you \"%M\""
  register_format :tell_from, "[f:magenta]You tell %N \"%M\""
  register_format :server, "[f:yellow:b][SERVER] %M"
end