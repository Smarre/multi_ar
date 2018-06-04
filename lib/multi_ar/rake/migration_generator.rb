
require "rails/generators/active_record/migration/migration_generator"
require "active_record/tasks/database_tasks"


# @api private
module ActiveRecordMigrations
  module Generators
    class MigrationGenerator < ::ActiveRecord::Generators::MigrationGenerator
      source_root ::ActiveRecord::Generators::MigrationGenerator.source_root

      def db_migrate_path
        databases = MultiAR::MultiAR::databases.first[1]
      end
    end
  end
end


