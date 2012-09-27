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
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fresh_redis"
  gem.require_paths = ["lib"]
  gem.version       = FreshRedis::VERSION

  gem.add_runtime_dependency 'redis'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'mock_redis', '0.5.2'
end
