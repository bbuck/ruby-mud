Laeron.config do |config|
  # General
  config.text.line_length = 80

  # Login
  config.login.valid_username = /\A[a-z]{2}[a-z'-]{0,17}[a-z]\z/i
  config.login.valid_password = /\A[\s\S]{8,255}\z/

  # Room
  config.room.default_description = "This room lacks a description."
  config.room.default_name = "This room has not been named."
end

require Laeron.root.join("config/environments", Laeron.env)