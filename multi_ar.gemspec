
require "date"

require_relative "lib/multi_ar/version"

Gem::Specification.new do |s|
  s.name        = "multi_ar"
  s.version     = MultiAR::VERSION
  s.date        = Date.today
  s.summary     = "Multi database feature set for ActiveRecord"
  s.description = "Core library for multi database support in any Ruby project for ActiveRecord.
  Migrations are supported by optional gem multi_ar_migrations."
  s.authors     = ["Samu Voutilainen"]
  s.email       = "smar@smar.fi"
  s.files       = Dir.glob("lib/**/*.rb") # TODO: which gem should have which files?
  s.executables = [ "multi_ar" ] # TODO: do we want executable like "mar"?
  s.homepage    = "http://smarre.github.io/multi_ar/"
  s.license     = "MIT"
  s.cert_chain  = ["certs/public.pem"]
  s.signing_key = "certs/private.pem" if $0 =~ /gem\z/
  s.add_runtime_dependency "optimist", "~> 3.0"
  s.add_runtime_dependency "activerecord", "~> 6.0"
  s.add_runtime_dependency "rake", "~> 12.3"
  s.add_runtime_dependency "safe_attributes", "~> 1.0"

  s.add_development_dependency "redcarpet", "~> 3.3"
  s.add_development_dependency "github-markup", "~> 3.0"
  s.add_development_dependency "cucumber", "~> 3.1"
  s.add_development_dependency "sqlite3", "~> 1.3"
  s.add_development_dependency "rspec", "~> 3.4"
end
