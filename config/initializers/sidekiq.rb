# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-cron'

Sidekiq.configure_client do |config|
  Sidekiq::Status.configure_client_middleware config, expiration: 24.hours.to_i
end

Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedule_file = Rails.root.join('config/sidekiq/cron_schedule.yml')
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file) if File.exist?(schedule_file)
  end
  Sidekiq::Status.configure_server_middleware config, expiration: 24.hours.to_i
  Sidekiq::Status.configure_client_middleware config, expiration: 24.hours.to_i
end
