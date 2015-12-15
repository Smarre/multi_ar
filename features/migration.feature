Feature: one major feature of multi_ar is migration creation. We want that feature to work properly.

  Scenario: my database has gotten to a position it needs to be altered
    Given I have a database with table "test_table"
    When I generate migration to add column "nya" to table "test_table"
    And I run migrations
    Then table "test_table" should contain column "nya"
