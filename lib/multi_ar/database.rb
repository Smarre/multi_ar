
# TODO: we don’t want to unconditionally load Rails as that gives too many unnecessary dependencies,
# but if we need it for something, it should be conditional dep through dep-gem or just used if present
#require "rails"
#require "rails/application"

require "active_record"
require "active_record/tasks/database_tasks"

require "erb"
require "yaml"

module MultiAR

  # @api private
  # Database functionality class.
  class Database

    # @todo test if this @@initialized thingy actually works, I’m not sure how it in practice works
    def self.initialize db_config: "config/database.yaml", migration_dir: "db/migrate"
      @@initialized ||= false
      return if @@initialized == true
      #Class.new(Rails::Application) unless Rails.application
      raise "The database configuration file was not found. You can be pass path to it with db_config attribute. Current path: #{db_config}" unless File.exist? db_config
      db_config_data = YAML.load(ERB.new(File.read db_config).result)
      include ActiveRecord::Tasks

      ActiveRecord::Base.configurations = ::ActiveRecord::Tasks::DatabaseTasks.database_configuration = db_config_data
      @@initialized = true
    end

    # @return real connection name, nil in case connection is not available
    def self.connection_name base_name
      raise "#{base_name} is not in databases configuration variable." unless MultiAR::databases.include? base_name
      return nil unless MultiAR::databases.include? base_name
      "#{base_name}_#{MultiAR.app.environment}"
    end

    # Expects config file to have the config in activerecord’s format.
    def self.mysql_client connection_name
      real_connection_name = self.connection_name connection_name
      @@mysql_client ||= {}
      return @@mysql_client[real_connection_name] unless @@mysql_client[real_connection_name].nil?
      raise "Invalid connection name #{real_connection_name}" unless config = self.database_config[real_connection_name]
      client = Mysql2::Client.new(
          host: config["host"],
          username: config["username"],
          password: config["password"],
          database: config["database"]
      )

      @@mysql_client[real_connection_name] ||= client
    end

    # @return database configuration in a hash.
    def self.database_config
      return @@db_config_cache unless (@@db_config_cache ||= nil).nil?

      db_config = MultiAR.app.db_config
      @@db_config_cache = Psych.load_file db_config
    end

  end
end
