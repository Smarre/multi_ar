
require_relative "../../lib/multi_ar"

# We first need to create instance of MultiAR

databases = { "testdb" => "/tmp" }
$multi_ar = MultiAR::MultiAR.new databases: databases, environment: "test", db_config: "config/database.yaml"

$multi_ar.rake_task "db:create"

# Then we can declare models

require_relative "../../lib/multi_ar/model"

class TestTable < MultiAR::Model
  establish_connection "testdb"
  self.table_name = "test_table"
end

at_exit do
  FileUtils.rm "tmp/testdb.sqlite3" if File.exist? "tmp/testdb.sqlite3"
  FileUtils.remove_entry_secure "/tmp/testdb" if Dir.exist? "/tmp/testdb"
end