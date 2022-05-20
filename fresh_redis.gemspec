require File.expand_path("../lib/fresh_redis/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Julian Doherty (madlep)"]
  gem.email         = ["madlep@madlep.com"]
  gem.description   = %q{Aggregate, expiring, recent data in Redis}
  gem.summary       = <<-TEXT.strip
    Use redis for working with recent temporal based data that can expiry gradually. Useful for things like "get a count all failed login attempts for the last hour"
  TEXT
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(spec)/})
  gem.name          = "fresh_redis"
  gem.require_paths = ["lib"]
  gem.version       = FreshRedis::VERSION

  gem.add_runtime_dependency 'redis'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'mock_redis'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'timecop'
end
