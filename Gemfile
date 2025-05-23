# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.4.2'

gem 'active_model_serializers'
gem 'bcrypt'
gem 'groupdate'
gem 'jwt'
gem 'ostruct'
gem 'pdf-reader'
gem 'pg', '~> 1.5', '>= 1.5.6'
gem 'plaid'
gem 'puma', '~> 6.0'
gem 'rails', '~> 7.2.1'
gem 'redis'
gem 'sidekiq'
gem 'sidekiq-cron'
gem 'sidekiq-status'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Needed until Ruby 3.3.4 is released https://github.com/ruby/ruby/pull/11006
gem 'net-pop', github: 'ruby/net-pop'

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem 'rack-cors'

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
  gem 'annotate'
  gem 'awesome_print'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'ruby-lsp', require: false
end

group :test do
  gem 'byebug', require: true
  gem 'mocha'
  gem 'simplecov', require: false
  gem 'timecop'
end
