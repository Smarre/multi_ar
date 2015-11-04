
require_relative "lib/multi_ar/version"

Gem::Specification.new do |s|
  s.name        = "multi_ar"
  s.version     = MultiAR::VERSION
  s.date        = Date.today
  s.summary     = "Multi database migrations and utilities for ActiveRecord"
  s.description = "Migration support and some other relevant utilities implemented using ActiveRecord
4."
  s.authors     = ["Samu Voutilainen"]
  s.email       = "smar@smar.fi"
  s.files       = Dir.glob("lib/**/*.rb")
  s.executables = [ "multi_ar" ] # TODO: do we want executable like "mar"?
  s.homepage    = "http://smarre.github.io/multi_ar/"
  s.license     = "MIT"
  s.cert_chain  = ["certs/public.pem"]
  s.signing_key = "certs/private.pem"
  s.add_runtime_dependency "trollop", "~> 2.1"
  s.add_runtime_dependency "activerecord", "~> 4"
  s.add_runtime_dependency "rails", "~> 4"
  s.add_runtime_dependency "railties", "~> 4"
  s.add_runtime_dependency "rake", "~> 10.4", ">= 10.4.2"
  #s.add_runtime_dependency "migration_comments", "~> 0.3.2"
  s.add_runtime_dependency "safe_attributes", "~> 1.0"
end
