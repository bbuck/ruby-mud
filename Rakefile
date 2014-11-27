require "./main"

task default: :run

# Load ActiveRecord tasks
include ActiveRecord::Tasks
DatabaseTasks.database_configuration = YAML.load(File.open(Laeron.root.join("config", "database.yml")))
DatabaseTasks.db_dir = "db"
DatabaseTasks.migrations_paths = "db"
ActiveRecord::Base.configurations = DatabaseTasks.database_configuration
ActiveRecord::Base.establish_connection(Laeron.env.to_sym)

desc "Run the Learon game server"
task :run do
  system("scripts/laeron run")
end

desc "Run the Laeron development console"
task :console do
  system("scripts/laeron console")
end

load "active_record/railties/databases.rake"

Dir.glob('lib/tasks/*.rake').each do |rake_file|
  import rake_file
end