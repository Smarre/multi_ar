
require "active_record"
require "active_record/tasks/database_tasks"

# In case there is no Rails available, let’s do simple class
begin
  require "rails"
  require "rails/application"

  Class.new(Rails::Application) unless Rails.application
rescue LoadError
  class Rails
    def self.root
      nil # TODO, we want MultiAR::root like thing somewhere
    end

    #def self.paths
    #  { "db/migrate" => "/dev/null" }
    #end
  end
end

# @api private
module Rake

  # Utility that defines Rake tasks of MultiAR
  class Tasks
    #include Rake::DSL

    # DSL wrapper partly copied from Rake::DSL.
    module DSL
      # Defines a Rake namespace (see Rake’s namespace() in dsl_definition.rb)
      def self.namespace(name=nil, &block)
        name = name.to_s if name.kind_of?(Symbol)
        name = name.to_str if name.respond_to?(:to_str)
        unless name.kind_of?(String) || name.nil?
          raise ArgumentError, "Expected a String or Symbol for a namespace name"
        end
        ::Rake.application.in_namespace(name, &block)
      end

      # Defines a Rake task’s description (see Rake’s desc() in dsl_definition.rb)
      def self.desc(description)
        ::Rake.application.last_description = description
      end

      # Defines a Rake task (see Rake’s task() in dsl_definition.rb)
      def self.task(*args, &block)
        ::Rake::Task.define_task(*args, &block)
      end
    end

    class << self
      attr_accessor :databases
      attr_accessor :environment
      attr_accessor :common_migrations
    end

    # When called, this declares Rake tasks of MultiAR,
    # most notably custom active record migration tasks.
    def self.define
      load "active_record/railties/databases.rake"

      # dunno if this is any use
        #task environment: 'db:load_config' do
        #  ActiveRecord::Base.establish_connection ActiveRecord::Tasks::DatabaseTasks.current_config
        #end

      DSL.namespace :db do

        DSL.desc "Creates a new migration file with the specified name"
        DSL.task :new_migration, :name, :options do |t, args|
          # Only migration generator requires Rails generators
          require "rails"
          require "rails/generators"
          require_relative "migration_generator"

          name = args[:name] || ENV["name"]
          options = args[:options] || ENV["options"]

          if MultiAR::MultiAR::databases.size != 1
            raise "You need to specify exactly one database for migration generation. See --databases. Given databases: #{MultiAR::MultiAR::databases.inspect}"
          end

          unless name
            generator = Rails::Generators.find_by_namespace "migration"
            desc = generator.desc.gsub(/`rails (?:g|generate) migration (\w+)`/, '`rake "db:new_migration[\\1]"`' ).
              gsub(/`rails (?:g|generate) migration (\w+) (.*)`/, '`rake "db:new_migration[\\1, \\2]"`' )
            puts [
              %Q{Usage: rake "#{t.name}[AddFieldToForm[, field[:type][:index]] field[:type][:index]]"},
              desc,
            ].join "\n\n"
            abort
          end
          params = [name]
          params.concat options.split(' ') if options
          Rails::Generators.invoke "active_record_migrations:migration", params,
            behavior: :invoke, destination_root: Rails.root
        end
      end

      multiple_databases_task "migrate", "db" do |database_name|
        establish_connection database_name

        context = ActiveRecord::MigrationContext.new(MultiAR::MultiAR.databases[database_name])
        context.migrate

        #MultiAR::MultiAR.migration_dirs.each do |dir|
        #  path = "#{dir}/#{database_name}/"
        #  # The database should be present only on one migration dir, so this will fail if there is more than one migration dir
        #  ActiveRecord::Migrator.migrate path if Dir.exist? path
        #end
      end

      multiple_databases_task "create", "db" do |database_name|
        establish_connection database_name
        ActiveRecord::Tasks::DatabaseTasks.create_current(connection_name(database_name))
      end

      multiple_databases_task "rollback", "db" do |database_name|
        establish_connection database_name
        step = ENV['STEP'] ? ENV['STEP'].to_i : 1

        context = ActiveRecord::MigrationContext.new(MultiAR::MultiAR.databases[database_name])
        context.rollback step
      end

      multiple_databases_task "forward", "db" do |database_name|
        establish_connection database_name
        step = ENV['STEP'] ? ENV['STEP'].to_i : 1

        context = ActiveRecord::MigrationContext.new(MultiAR::MultiAR.databases[database_name])
        context.forward step
      end

      multiple_databases_task "down", "db:migrate" do |database_name|
        establish_connection database_name
        raise "db:down is used to go back to certain version. Use db:rollback if you want to go back n migrations." unless ENV["VERSION"]
        version = ENV["VERSION"]

        context = ActiveRecord::MigrationContext.new(MultiAR::MultiAR.databases[database_name])
        context.down version
      end

      multiple_databases_task "up", "db:migrate" do |database_name|
        establish_connection database_name
        raise "db:up is used to go to certain version. Use db:forward if you want to go up n migrations." unless ENV["VERSION"]
        version = ENV["VERSION"]

        context = ActiveRecord::MigrationContext.new(MultiAR::MultiAR.databases[database_name])
        context.up version
      end

      multiple_databases_task "status", "db:migrate" do |database_name|
        establish_connection database_name

        unless ActiveRecord::SchemaMigration.table_exists?
          abort "Schema migrations table does not exist yet."
        end

        #raise "db:up is used to go to certain version. Use db:forward if you want to go up n migrations." unless ENV["VERSION"]
        #version = ENV["VERSION"]

        #context = ActiveRecord::MigrationContext.new(MultiAR::MultiAR.databases[database_name])
        #context.up version

        # output
        puts "\ndatabase: #{ActiveRecord::Base.connection_config[:database]}\n\n"
        puts "#{'Status'.center(8)}  #{'Migration ID'.ljust(14)}  Migration Name"
        puts "-" * 50
        ActiveRecord::Base.connection.migration_context.migrations_status.each do |status, version, name|
          puts "#{status.center(8)}  #{version.ljust(14)}  #{name}"
        end
        puts

      end

      multiple_databases_task "drop", "db" do |database_name|
        establish_connection database_name
        ActiveRecord::Tasks::DatabaseTasks.drop_current(connection_name(database_name))
      end
    end

  private

    def self.rename_task name, namespace = nil
      new_name = "old_#{name}"
      #new_name = "#{namespace}:#{new_name}" unless namespace.nil?
      ::Rake::Task[name].rename(new_name)
      old_comment = ::Rake::Task[new_name].comment
      ::Rake::Task[new_name].clear_comments
      old_comment
    end

    def self.multiple_databases_task name_without_namespace, namespace = nil
      name = (namespace && name) || "#{namespace}:#{name_without_namespace}"
      old_comment = rename_task name, namespace

      databases = MultiAR::MultiAR::databases

      DSL.desc "Runs task #{name} for all selected databases"
      DSL.task name.to_sym do
        databases.each do |database_name, migration_path|
          ::Rake::Task["#{name}:#{database_name}"].invoke
        end
      end

      databases.each do |database_name, migration_path|
        DSL.desc old_comment
        DSL.task :"#{name}:#{database_name}" do
          yield database_name
        end
      end
    end

    def self.connection_name database_name
      "#{database_name}_#{environment}"
    end

    def self.establish_connection database_name
      ActiveRecord::Base.establish_connection connection_name(database_name).to_sym
    end

  end
end

