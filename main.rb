$:.unshift("./lib")

require "rubygems"
require "bundler/setup"
Bundler.require(:default, (ENV["LAERON_ENV"] || "development").downcase.to_sym)

# Require special gems
require "active_record"

# Files
require "configuration"
require "laeron"

# Load models
Dir.glob(Laeron.root.join("lib/models/**/*")).each do |model_file|
  require model_file
end

begin
  ActiveRecord::Base.connection
rescue ActiveRecord::ConnectionNotEstablished => e
  ActiveRecord::Base.configurations = YAML.load(File.open(Laeron.root.join("config", "database.yml")))
  ActiveRecord::Base.establish_connection(Laeron.env)
end

# Server Files
require "input/input_manager"
require "client_connection"

# Load configuration
require Laeron.root.join("config/application")