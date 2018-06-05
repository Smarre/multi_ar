
require_relative "multi_ar/rake/ext"
require_relative "multi_ar/rake/tasks"

require_relative "multi_ar/database"

# Main module.
module MultiAR

  # Base of MultiAR gem.
  #
  # Must be initialized before most actions works, that relies on MultiAR#app for getting configuration.
  class MultiAR

    attr_reader :db_config
    attr_reader :environment

    # @api private
    # This will always be overridden, when MultiAR is initialized. Don’t try to do any funny logic with this.
    @@__databases = {}

    class << self
      # Instance of MultiAR::MultiAR, automatically assigned by MultiAR::MultiAR#new.
      # Used internally in the gem, to access configuration and other internal parts.
      attr_accessor :app
    end

    # @param databases array of available databases
    # @todo config file is overriding parameters passed here... I think it should be other way around, but need more custom logic for that :/
    def initialize databases:, environment: "development", config: "config/settings.yaml", db_config: "config/database.yaml", verbose: false, migration_framework: true

      # first load config
      if not config.nil? and File.exist? config
        require "psych"
        config = Psych.load_file config
        b = binding
        config.each do |key, value|
          if key == "databases"
            out = {}
            value.each do |database|
              out[database["database"]] = database["migration_path"]
            end
            value = out
          end
          b.local_variable_set key.to_sym, value
        end
      end

      # then check that we have data in format we want it to be
      raise "#{db_config} is not valid path to a file. Try specifying --db-config <path> or configuring it in the configuration file." if db_config.nil? or !File.exist?(db_config)
      raise "databases is not responding to :each. Try passing passing --databases <database> or configuring it in the configuration file." unless databases.respond_to? :each

      parse_databases_input databases

      #@databases = databases
      @db_config = db_config
      @environment = environment
      @migration_framework = migration_framework
      #@@migration_dirs = migration_dirs unless migration_dirs.empty? # This takes care of that it will only be overridden if there is any given values, making default configs work
      #ActiveRecord::Tasks::DatabaseTasks.migrations_paths = migration_dirs

      Database.initialize db_config: db_config

      #ActiveRecord::Tasks::DatabaseTasks.class_eval { attr_accessor :sub_db_dir }
      #ActiveRecord::Tasks::DatabaseTasks.sub_db_dir = databases.first # TODO: I don’t think this is how it should work

      @rake = ::Rake::Application.new
      ::Rake.application = @rake
      @rake.init
      ::Rake::TaskManager.record_task_metadata = true

      #Rake::Tasks.databases = databases
      Rake::Tasks.environment = environment
      Rake::Tasks.define

      @@verbose = verbose

      MultiAR.app = self
    end

    # A helper method to add migrations for multiple databases that reside in same location.
    #
    # Expects the given directory contain subdirectories that contain the actual migrations.
    # For example, `db/migrate/_db_name_`, where `db/migrate` is dir given as an argument to this
    # method and `_db_name_` is name of the database.
    def self.add_migration_dir dir
      raise "Directory #{dir} does not exist." unless Dir.exist? dir

      Dir.chdir dir do
        dbs = Dir.glob "*/"
        dbs.each do |database|
          add_database database, "#{dir}/#{database.chop}"
        end
      end
    end

    # Array of paths to directories where migrations resides.
    # @see add_database
    def self.migration_dirs
      ActiveRecord::Tasks::DatabaseTasks.migrations_paths
    end

    def self.migration_dir_for database_name
      ActiveRecord::Tasks::DatabaseTasks.migrations_paths
    end

    # Outputs contents if verbose flag has been passed.
    def self.verb str
      return unless @@verbose
      puts str
    end

    # Add a database and its migration path. For standard Rails setup, this would be "customdbname", “db/migrate”.
    #
    # The directory structure of how MultiAR uses the path is a bit different from traditional way: for each
    # database, there is directory inside the migration dir.
    #
    # For example, if project uses database named “messy_database” and migration dir is “my/migration/dir”,
    # migrations would be looked from path “my/migration/dir/messy_database”.
    #
    # @note often you want to add full path to this dir, `__dir__` is useful for this.
    def self.add_database database_name, migration_path
      if @migration_framework
        raise "Migration dir #{migration_path} does not exist." unless Dir.exist? migration_path
        ActiveRecord::Tasks::DatabaseTasks.migrations_paths << migration_path
      end
      @@__databases[database_name] = migration_path
    end

    # @todo this shows rake in start of the command, we want to show multi_ar instead.
    def list_tasks all_rake_tasks: false
      @rake.options.show_all_tasks = true if all_rake_tasks
      @rake.options.show_tasks = :tasks
      @rake.options.show_task_pattern = // # all tasks; we don’t have support for string-matching tasks
      @rake.display_tasks_and_comments
    end

    # Invokes Rake task from `task_name`
    def rake_task task_name
      @rake.invoke_task task_name
    end

    def self.databases
      @@__databases
    end

    private

    def parse_databases_input dbs
      if dbs.kind_of? Array
        dbs.each do |database|
          ::MultiAR::MultiAR::add_database database, "db/migrate/#{database}"
        end
        return
      end

      raise "input databases needs to be either Hash or Array" unless dbs.kind_of? Hash

      dbs.each do |database, migration_path|
        ::MultiAR::MultiAR::add_database database, migration_path
      end
    end
  end
end