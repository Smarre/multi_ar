
Given(/^I have a database with table "([^"]*)"$/) do |table_name|
  sqlite = TestTable.connection.raw_connection
  sqlite.execute "CREATE TABLE #{table_name} ( funkyvalue varchar(30) )"
end


When(/^I generate migration to add column "([^"]*)" to table "([^"]*)"$/) do |column, table|
  $multi_ar.rake_task "db:new_migration[AddNewColumnToTable]"
  filename = Dir.glob("/tmp/testdb/*_add_new_column_to_table.rb").first
  content = File.read filename
  new_content = content.gsub /def change\n/, "def change\n    add_column '#{table}', '#{column}', :string\n"
  File.open(filename, "w") do |file|
    file.puts new_content
  end
end

When(/^I run migrations$/) do
  $multi_ar.rake_task "db:migrate"
end

Then(/^table "([^"]*)" should contain column "([^"]*)"$/) do |table, column|
  TestTable.reset_column_information
  expect(TestTable.column_names).to contain_exactly( "funkyvalue", column )
end

