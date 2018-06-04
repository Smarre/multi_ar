
require "rails/generators/active_record/migration/migration_generator"
require "active_record/tasks/database_tasks"


# @api private
module ActiveRecordMigrations
  module Generators
    class MigrationGenerator < ::ActiveRecord::Generators::MigrationGenerator
      source_root ::ActiveRecord::Generators::MigrationGenerator.source_root

      def db_migrate_path
        dir = ::ActiveRecord::Tasks::DatabaseTasks.migrations_paths.first
        db_dir = ::ActiveRecord::Tasks::DatabaseTasks.sub_db_dir
        "#{dir}/#{db_dir}"
      end
    end
  end
end


