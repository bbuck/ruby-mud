require "./main"

# Load ActiveRecord tasks
include ActiveRecord::Tasks
DatabaseTasks.database_configuration = YAML.load(File.open(Laeron.root.join("config", "database.yml")))
DatabaseTasks.db_dir = "db"
DatabaseTasks.migrations_paths = "db"
ActiveRecord::Base.configurations = DatabaseTasks.database_configuration
ActiveRecord::Base.establish_connection(Laeron.env.to_sym)

# Required for active record migrations
task :environment do
  # empty on purpose
end

load "active_record/railties/databases.rake"

Dir.glob('lib/tasks/*.rake').each do |rake_file|
  import rake_file
end