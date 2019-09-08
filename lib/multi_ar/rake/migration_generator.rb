
require "rails/generators/active_record/migration/migration_generator"
require "active_record/tasks/database_tasks"


# @api private
#
# Overridden from Active Record to have custom migration path.
module ActiveRecordMigrations

  # Overridden from Active Record to have custom migration path.
  module Generators

  # Overridden from Active Record to have custom migration path.
    class MigrationGenerator < ::ActiveRecord::Generators::MigrationGenerator
      source_root ::ActiveRecord::Generators::MigrationGenerator.source_root

      # Overridden from Active Record to have custom migration path.
      def db_migrate_path
        database_name = MultiAR::MultiAR::databases.first[0]
        MultiAR::MultiAR::solve_migration_path database_name
      end
    end
  end
end


