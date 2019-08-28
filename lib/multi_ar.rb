
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

    @default_migration_path = "db/migrate"

    class << self
      # Instance of MultiAR::MultiAR, automatically assigned by MultiAR::MultiAR#new.
      # Used internally in the gem, to access configuration and other internal parts.
      attr_accessor :app
    end

    # @param databases array of available databases
    # @todo config file is overriding parameters passed here... I think it should be other way around, but need more custom logic for that :/
    def initialize databases: nil, environment: "development", config: "config/settings.yaml", db_config: "config/database.yaml", verbose: false, migrations_from_gem: nil

      # first load config
      if not config.nil? and File.exist? config
        require "psych"
        config = Psych.load_file config
        b = binding
        config.each do |key, value|
          # If databases have been passed, we don’t have much reason to override it from config
          if key != "databases" || databases.nil?
            b.local_variable_set key.to_sym, value
          end
        end
      end

      # then check that we have data in format we want it to be
      raise "#{db_config} is not valid path to a file. Try specifying --db-config <path> or configuring it in the configuration file." if db_config.nil? or !File.exist?(db_config)
      #raise "databases is not responding to :each. Try passing passing --databases <database> or configuring it in the configuration file." unless databases.respond_to? :each

      # One can run migrations from a gem, instead of current project.
      load_migration_gem migrations_from_gem, databases if not migrations_from_gem.nil?

      parse_databases_input databases unless databases.nil?

      #@databases = databases
      @db_config = db_config
      @environment = environment
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
      unless migration_path.nil?
        raise "Migration dir #{migration_path} does not exist." unless Dir.exist? migration_path
        begin
          ActiveRecord::Tasks::DatabaseTasks.migrations_paths << migration_path
        rescue NameError
          # multi_ar can be used without migration support, so adding a database to migration paths is only necessary when actually running migrations.
        end
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

    # Returns calculated migration path or if path have not been given, fallback to default db/migrate/DB_NAME if it exists.
    def self.solve_migration_path database_name
      path = self.databases[database_name]
      if path.nil?
        path = "db/migrate/#{database_name}"
        raise "Trying to use migrations for non-existing database. Please specify database if you have migrations in custom location. Given database: #{database_name}" unless File.exist? path
      end

      path
    end

    # TODO: remember to remove these if not needed...
    # Helper to resolve a path to database
    #def self.resolve_database_path

    #end

    #def self.resolve_databases_paths
    #end

    private

    def load_migration_gem migrations_from_gem, databases
      # If the gem is not installed, we just want to fail.
      gem migrations_from_gem

      spec = Gem.loaded_specs[migrations_from_gem]
      gem_dir = nil
      if spec.respond_to? :full_gem_path
        gem_dir = spec.full_gem_path
      else
        require_paths = spec["require_paths"]
        gem_dir = require_paths[0]
      end

      # This file contains gem specific details which can be used to bootstrap MultiAR.
      # There could be default values, but for security, as loading arbitrary gems accidentally could cause hard-to-recognize security bugs, since migrations are plain Ruby code.
      # TODO: document contents of that file somewhere.
      info_file = "#{gem_dir}/config/multi_ar_gem.yaml"

      raise "File #{info_file} does not exist. Please check that your gem contains config/multi_ar_gem.yaml for automatic operation." unless File.exist? info_file
      yaml = YAML.load_file info_file

      migration_dir = yaml["migration_dir"]

      # Put in gem’s migration path, so stuff should just magically work

      databases.each do |database, migration_path|
        databases[database] = "#{gem_dir}/#{migration_dir}"
      end
    end

    # Supports three different input formats:
    #
    # 1. Array with strings of database names
    # 2. Array with hashes of { "database" => "db_name", "migration_path" => "/path/to/migrations" }
    # 3. Hash with key as database name and value as migration path
    def parse_databases_input dbs
      if dbs.kind_of? Array
        dbs.each do |database|
          if database.kind_of? Hash
            ::MultiAR::MultiAR::add_database database["database"], database["migration_path"]
          else
            ::MultiAR::MultiAR::add_database database, "#{default_migration_path}/#{database}"
          end
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