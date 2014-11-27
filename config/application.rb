Laeron.config do |config|
  config.text.line_length = 80
end

require Laeron.root.join("config/environments", Laeron.env)