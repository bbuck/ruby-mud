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
  exec("scripts/laeron run")
end

desc "Run the Laeron development console"
task :console do
  exec("scripts/laeron console")
end

desc "Perform a migration through the Laeron script with the given name."
task :create_migration, [:name] do |t, args|
  if args[:name].nil?
    puts "A name for the migration must be specified!"
  else
    exec("scripts/laeron migrate #{args[:name]}")
  end
end

# Required for active record migrations
task :environment do
  # empty on purpose
end

load "active_record/railties/databases.rake"

Dir.glob('lib/tasks/*.rake').each do |rake_file|
  import rake_file
end