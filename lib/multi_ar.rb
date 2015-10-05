

require_relative "multi_ar/rake/ext"
require_relative "multi_ar/rake/tasks"

require_relative "multi_ar/database"

module MultiAR

  # Base of Slam gem.
  #
  # Must be initialized before most actions works, that relies on Slam#app for getting configuration.
  class MultiAR

    attr_reader :databases
    attr_reader :db_config
    attr_reader :environment

    class << self
      # Instance of MultiAR::MultiAR, automatically assigned by MultiAR::MultiAR#new.
      # Used internally in the gem, to access configuration and other internal parts.
      attr_accessor :app
    end

    # @param databases array of available databases
    # @todo config file is overriding parameters passed here... I think it should be other way around, but need more custom logic for that :/
    def initialize databases:, environment: "development", config: "config/multi_ar.yaml", db_config: "config/database.yaml", common_migrations: true, migration_dir: "db/migrate"

      # first load config
      if File.exist? config
        require "psych"
        config = Psych.load_file config
        b = binding
        config.each do |key, value|
          b.local_variable_set key.to_sym, value
        end
      end

      # then check that we have data in format we want it to be
      raise "#{db_config} is not valid path to a file. Try specifying --db-config <path> or configuring it in the configuration file." unless File.exist?(db_config)
      raise "databases is not responding to :each. Try passing passing --databases <database> or configuring it in the configuration file." unless databases.respond_to? :each

      @databases = databases
      @db_config = db_config
      @environment = environment

      Database.initialize db_config: db_config, migration_dir: migration_dir

      ActiveRecord::Tasks::DatabaseTasks.class_eval { attr_accessor :sub_db_dir }
      ActiveRecord::Tasks::DatabaseTasks.sub_db_dir = databases.first # TODO: I don’t think this is how it should work

      @rake = ::Rake::Application.new
      ::Rake.application = @rake
      @rake.init
      ::Rake::TaskManager.record_task_metadata = true

      Rake::Tasks.databases = databases
      Rake::Tasks.environment = environment
      Rake::Tasks.common_migrations = common_migrations
      Rake::Tasks.migration_dir = migration_dir
      Rake::Tasks.define

      MultiAR.app = self
    end

    # @todo this shows rake in start of the command, we want to show multi_ar instead.
    def list_tasks all_rake_tasks: false
      @rake.options.show_all_tasks = true if all_rake_tasks
      @rake.options.show_tasks = :tasks
      @rake.options.show_task_pattern = // # all tasks; we don’t have support for string-matching tasks
      @rake.display_tasks_and_comments
    end

    def rake_task task_name
      @rake.invoke_task task_name
    end
  end
end

# For convenience, it may make shorter namespace.
Mar = MultiAR # TODO: there is Mar gem, maybe we should avoid this to avoid conflicts?
MultiAr = MultiAR