
# TODO: we don’t want to unconditionally load Rails as that gives too many unnecessary dependencies,
# but if we need it for something, it should be conditional dep through dep-gem or just used if present
require "rails"
require "rails/generators"

require "active_record"
require "active_record/tasks/database_tasks"

require_relative "migration_generator"

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
          name = args[:name] || ENV["name"]
          options = args[:options] || ENV["options"]

          raise "You need to specify exactly one database for migration generation. See --databases. Given databases: #{databases.inspect}" if databases.size != 1

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

        MultiAR::MultiAR.migration_dirs.each do |dir|
          path = "#{migration_dir}/#{database_name}/"
          # The database should be present only on one migration dir, so this will fail if there is more than one migration dir
          ActiveRecord::Migrator.migrate path if Dir.exist? path
        end
      end

      multiple_databases_task "create", "db" do |database_name|
        establish_connection database_name
        ActiveRecord::Tasks::DatabaseTasks.create_current(connection_name(database_name))
      end

      multiple_databases_task "rollback", "db" do |database_name|
        establish_connection database_name
        step = ENV['STEP'] ? ENV['STEP'].to_i : 1
        MultiAR::MultiAR.migration_dirs.each do |dir|
          path = "#{migration_dir}/#{database_name}/"
          # The database should be present only on one migration dir, so this will fail if there is more than one migration dir
          ActiveRecord::Migrator.rollback(path, step) if Dir.exist? path
        end
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

      DSL.desc "Runs task #{name} for all selected databases"
      DSL.task name.to_sym do
        databases.each do |database_name|
          ::Rake::Task["#{name}:#{database_name}"].invoke
        end
      end

      databases.each do |database_name|
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

