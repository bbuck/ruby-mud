$:.unshift("./lib")

require "rubygems"
require "bundler/setup"
Bundler.require(:default, (ENV["LAERON_ENV"] || "development").downcase.to_sym)

# Require special gems
require "active_record"

# Files
require "configuration"
require "laeron"
Laeron.require_all(Laeron.root.join("lib", "utils", "**", "*"))
Laeron.require_all(Laeron.root.join("lib", "extensions", "**", "*"))
Laeron.require_all(Laeron.root.join("lib", "es_locks", "**", "*"))
require "eleetscript_env_setup.rb"

# Load models
Laeron.require_all(Laeron.root.join("lib", "models", "concerns", "*"))
Laeron.require_all(Laeron.root.join("lib", "models", "*.rb"))

begin
  ActiveRecord::Base.connection
rescue ActiveRecord::ConnectionNotEstablished => e
  ActiveRecord::Base.configurations = YAML.load(File.open(Laeron.root.join("config", "database.yml")))
  ActiveRecord::Base.establish_connection(Laeron.env.to_sym)
end

# Server Files
require "input/input_manager"
require "client_connection"

# Load configuration
require Laeron.root.join("config/application")