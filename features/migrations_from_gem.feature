Feature: In some projects, especially on commercial side, it is easy to deploy migrations as a gem to everyone working with a project.
The easier it is to use the migrations in a project, the better.

  @broken
  Scenario: A project has a new developer, and she needs to get to actual work as fast as possible
    Given I have a gem with following data:
      | Fields    | Values            |
      | gem_name  | gem_migration_gem |
      | db_name   | gem_migration_db  |
      | table     | gem_migration     |
      | column    | miu               |
    And I run "multi_ar --gem gem_migration_gem --task db:migrate --databases gem_migration_db"
    Then table "gem_migration" in database "gem_migration_db" should contain field "miu"
