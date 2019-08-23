
GEMFILE_TEMPLATE = <<EOF
require "date"

require_relative "lib/multi_ar/version"

Gem::Specification.new do |s|
  s.name        = "__GEM_NAME__"
  s.version     = "0.0"
  s.date        = #{Date.today}
  s.summary     = "Test gem"
  s.authors     = ["Test"]
  s.files       = Dir.glob("db/**/*.rb")
  s.homepage    = "http://smarre.github.io/multi_ar/"
  s.license     = "MIT"
  s.add_runtime_dependency "multi_ar"
end
EOF


Given("I have a gem with following data:") do |table|
  data = table.rows_hash

  gem_name = data["gem_name"]
  table_name data["table"]
  db_name = data["db_name"]
  field_name = data["column"]

  # TODO: how cleanup of this dir works?
  gem_dir = "/tmp/testdb"

  steps %{
    Given I have a multi_ar project named "#{gem_name}" with database "#{db_name}"
    When I run "multi_ar -d #{gem_name}:#{gem_dir} -t 'db:new_migration[Create#{table_name.camelize}, #{field_name}:string]'" for that project
  }

  template = GEMFILE_TEMPLATE.sub "__GEM_NAME__", gem_name
  File.open "#{gem_dir}/#{gem_name}.gemspec", "w" do |f|
    f.write template
  end

  steps %{
    When I run "gem build #{gem_name}.gemspec" for that project
  }

  # TODO: not finished; not going to spend time figuring out how to handle the command with test without too much hackery.
end
