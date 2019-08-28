Feature: We have CLI interface, which can be used for various tasks, like migrations and bootstrapping an environment

  @project_test
  Scenario: I have existing project, which suddenly is in need of a database. I want to employ multi_ar for that project.
    Given I have existing project named "interface_test_project"
    And project "interface_test_project" has existing bundle with multi_ar
    When I run "multi_ar --init '.' -d interface_test_db" for that project
    Then there should be following files:
      | README.md |
      | config/database.yaml |
    And "README.md" should mention "interface_test_project"
    And "config/database.yaml" should contain database config for "interface_test_db"

  @project_test
  Scenario: After I have integrated multi_ar to my project, I want to use it to generate some migrations
    Given I have a multi_ar project named "integrated_test_project" with database "integrated_test_db"
    When I run "multi_ar -d integrated_test_db:/tmp/integrated_test_project -t 'db:new_migration[CreateTestTable, test_value:string]'" for that project
    And I run "multi_ar -d integrated_test_db:/tmp/integrated_test_project -t db:migrate -e test" for that project
    Then table "test_tables" in database "integrated_test_db" should contain field "test_value"

  @project_test
  Scenario: When I don’t want to create migrations, but only use existing database, I don’t really migration paths at all.
    Given I have a multi_ar project named "without_migration_path" with database "migration_db"
    When I run "multi_ar -d migration_db -t 'db:new_migration[CreateTestTable, test_value:string]'" for that project
    And I run "multi_ar -d migration_db -t db:migrate -e test" for that project
    Then table "test_tables" in database "migration_db" should contain field "test_value"