Feature: We have CLI interface, which can be used for various tasks, like migrations and bootstrapping an environment

  @project_test
  Scenario: I have existing project, which suddenly is in need of a database. I want to employ multi_ar for that project.
    Given I have existing project named "interface_test_project"
    And project "interface_test_project" has existing bundle with multi_ar
    When I successfully run `multi_ar --init '.' -d interface_test_db`
    Then there should be following files:
      | README.md |
      | config/database.yaml |
    And "README.md" should mention "interface_test_project"
    And "config/database.yaml" should contain database config for "interface_test_db"

  @project_test
  Scenario: After I have integrated multi_ar to my project, I want to use it to generate some migrations
    Given I have a multi_ar project named "interface_test_project" with database "interface_test_project"
    When I run "multi_ar -d interface_test_project:/tmp/testdb -t 'db:new_migration[CreateTestTable, test_value:string]'" for that project
    And I run "multi_ar -d interface_test_project -t db:migrate -e test" for that project
    Then table "test_tables" in database "interface_test_project" should contain field "test_value"