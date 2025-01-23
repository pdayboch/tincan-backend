# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require 'simplecov'

SimpleCov.start 'rails' do
  enable_coverage :branch

  add_filter '/test/' # Exclude the test directory from coverage
  add_filter '/config/'
  add_filter '/app/channels/'
  add_filter '/app/mailers/'
end

require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'
require 'mocha/minitest'
require 'sidekiq/testing'

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # 2024-09-15 Disable temporarily parallelize since it breaks simplecov reports.
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end
