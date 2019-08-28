
require "rails/generators/active_record/migration/migration_generator"
require "active_record/tasks/database_tasks"


# @api private
module ActiveRecordMigrations
  module Generators
    class MigrationGenerator < ::ActiveRecord::Generators::MigrationGenerator
      source_root ::ActiveRecord::Generators::MigrationGenerator.source_root

      def db_migrate_path
        database_name = MultiAR::MultiAR::databases.first[0]
        MultiAR::MultiAR::solve_migration_path database_name
      end
    end
  end
end


