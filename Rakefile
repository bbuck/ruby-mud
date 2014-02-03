require "./main"

task :default, :run

# Load ActiveRecord tasks
include ActiveRecord::Tasks
DatabaseTasks.database_configuration = YAML.load(File.open(Laeron.root.join("config", "database.yml")))
DatabaseTasks.db_dir = "db"
DatabaseTasks.migrations_paths = "db"
ActiveRecord::Base.configurations = DatabaseTasks.database_configuration
ActiveRecord::Base.establish_connection(Laeron.env)

desc "Run the Learon game server"
task :run do
  `scripts/laeron start`
end

desc "Run the Laeron development console"
task :console do
  `scripts/laeron console`
end

desc "Load the environment"
task :environment do
end

load "active_record/railties/databases.rake"

Dir.glob('lib/tasks/*.rake').each do |rake_file|
  import rake_file
end