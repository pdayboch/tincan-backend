source 'https://rubygems.org'

ruby '3.3.6'

gem 'activejob-status'
gem 'active_model_serializers'
gem 'bcrypt'
gem 'groupdate'
gem 'ostruct'
gem 'pdf-reader'
gem 'pg', '~> 1.5', '>= 1.5.6'
gem 'puma', '~> 6.0'
gem 'rails', '~> 7.2.1'
gem 'redis'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Needed until Ruby 3.3.4 is released https://github.com/ruby/ruby/pull/11006
gem 'net-pop', github: 'ruby/net-pop'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem 'rack-cors'

group :development, :test do
  gem 'debug', platforms: %i[mri windows]
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
  gem 'annotate'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'ruby-lsp', require: false
end

group :test do
  gem 'mocha'
  gem 'simplecov', require: false
  gem 'timecop'
end
