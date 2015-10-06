
require "rails/generators/active_record/migration/migration_generator"
require "active_record/tasks/database_tasks"


# @api private
module ActiveRecordMigrations
  module Generators
    class MigrationGenerator < ::ActiveRecord::Generators::MigrationGenerator
      source_root ::ActiveRecord::Generators::MigrationGenerator.source_root

      def create_migration_file
        set_local_assigns!
        validate_file_name!
        dir = ::ActiveRecord::Tasks::DatabaseTasks.migrations_paths.first
        db_dir = ::ActiveRecord::Tasks::DatabaseTasks.sub_db_dir
        migration_template @migration_template, "#{dir}/#{db_dir}/#{file_name}.rb"
      end
    end
  end
end


