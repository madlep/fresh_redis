require File.expand_path("../lib/fresh_redis/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Julian Doherty (madlep)"]
  gem.email         = ["madlep@madlep.com"]
  gem.description   = %q{Aggregate, expiring, recent data in Redis}
  gem.summary       = <<-TEXT.strip
    Store time series data that expires in a FIFO manner (i.e. show me stuff for the last 60 minutes)
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
end
