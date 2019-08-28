
require "fileutils"

After("@project_test") do
  FileUtils.remove_entry_secure("/tmp/#{@project_name}")
end

Given(/^I have a multi_ar project named "([^"]*)" with database "([^"]*)"$/) do |project_name, database|
  @project_name = project_name
  Dir.chdir "/tmp" do
    command = "multi_ar --init #{project_name} -d #{database}"
    #puts "Running #{command}"
    puts `#{command}`
    expect($?.exitstatus).to eq(0)
  end
end

Given(/^I have existing project named "([^"]*)"$/) do |project_name|
  Dir.chdir "/tmp" do
    @project_name = project_name
    Dir.mkdir project_name
    Dir.chdir project_name do
      File.open "Gemfile", "w" do |f|
        gemfile = <<-EOF
        # A sample Gemfile
        source 'https://rubygems.org'
        EOF
        f.write gemfile
      end
    end
  end
end

Given(/^project "([^"]*)" has existing bundle with multi_ar$/) do |project_name|
  Dir.chdir "/tmp" do
    Dir.chdir project_name do
      File.open "Gemfile", "w" do |f|
        gemfile = <<-EOF
        # A sample Gemfile
        source "https://rubygems.org"

        gem "multi_ar"
        EOF
        f.write gemfile
      end

      `bundle install`
      expect($?.exitstatus).to eq(0)
    end
  end
end

Given("I create directory {string}") do |dir|
  FileUtils.mkdir_p dir
end

Then(/^there should be following files:$/) do |table|
  # table is a Cucumber::Core::Ast::DataTable

  table.raw.each do |row|
    expect(File.exist? row[0]).to be_truthy
  end
end

Then(/^"([^"]*)" should mention "([^"]*)"$/) do |filename, content|
  expect(File.open("/tmp/#{@project_name}/#{filename}").readlines.join).to include(content)
end

Then(/^"([^"]*)" should contain database config for "([^"]*)"$/) do |filename, database|
  expect(File.open("/tmp/#{@project_name}/#{filename}").readlines.join).to include("#{database}_development:")
end

Then(/^table "([^"]*)" in database "([^"]*)" should contain field "([^"]*)"$/) do |table, database, field|
  Dir.chdir "/tmp" do
    Dir.chdir @project_name do
      db = SQLite3::Database.new "db/#{database}_test.sqlite3"
      rows = db.execute("SELECT name FROM sqlite_master WHERE type = 'table'")
      puts rows.inspect
      expect(rows.count).to eq(4)
      expect(rows[0][0]).to eq("schema_migrations")
      expect(rows[1][0]).to eq("ar_internal_metadata")
      expect(rows[2][0]).to eq(table)
      expect(rows[3][0]).to eq("sqlite_sequence")

      rows = db.execute("pragma table_info('#{table}')")
      puts rows.inspect
      expect(rows.count).to eq(2)
      expect(rows[0][1]).to eq("id")
      expect(rows[1][1]).to eq(field)
    end
  end
end

