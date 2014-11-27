class ChannelFormatter
  class << self
    def add_channel_format(name, format)
      formats[name] = format
    end

    def format(name, data)
      format = formats[name]
      if format.nil?
        ""
      else
        data.each do |key, value|
          format.gsub!(key, value)
        end
        format
      end
    end

    private

    def formats
      @formats ||= {}
    end
  end
end

ChannelFormatter.add_channel_format(:say_from, "[f:cyan:b]You say, \"%M\"")
ChannelFormatter.add_channel_format(:say_to, "[f:cyan:b]%N says, \"%M\"")
ChannelFormatter.add_channel_format(:yell, "[f:red:b]%N yells, \"%M\"")
ChannelFormatter.add_channel_format(:xpost, "[f:green]%M")
ChannelFormatter.add_channel_format(:post, "[f:green]%N %M")
ChannelFormatter.add_channel_format(:ooc, "[OOC] %N: %M")
ChannelFormatter.add_channel_format(:general, "[f:white:b]([f:cyan]GENERAL[f:white:b]) [f:green]%N [f:white:b]- [reset]%M")
ChannelFormatter.add_channel_format(:trade, "[f:white:b]([f:blue]TRADE[f:white:b]) [f:green]%N [f:white:b]- [reset]%M")
ChannelFormatter.add_channel_format(:newbie, "[f:white:b]([f:green]NEWBIE[f:white:b]) [f:green]%N [f:white:b]- [reset]%M")
ChannelFormatter.add_channel_format(:tell_to, "[f:magenta]%N tells you \"%M\"")
ChannelFormatter.add_channel_format(:tell_from, "[f:magenta]You tell %N \"%M\"")
ChannelFormatter.add_channel_format(:server, "[f:yellow:b][SERVER] %M")