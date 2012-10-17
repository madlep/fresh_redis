source 'https://rubygems.org'

# Specify your gem's dependencies in fresh_redis.gemspec
gemspec

# HAX to allow native file change detection to work on linux AND OSX
# from https://github.com/carlhuda/bundler/issues/663#issuecomment-2849045
group :development do
  gem 'rb-fsevent', :require => RUBY_PLATFORM.include?('darwin') && 'rb-fsevent'
  gem 'rb-inotify', :require => RUBY_PLATFORM.include?('linux') && 'rb-inotify'
end
