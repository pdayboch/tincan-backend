# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class ApiTest < ActiveSupport::TestCase
    test 'initializes with correct environment in development' do
      Rails.env.stubs(:production?).returns(false)

      configuration = nil
      Plaid::Configuration.any_instance.stubs(:server_index=).with do |index|
        configuration = index
        true
      end

      PlaidServices::Api.new
      assert_equal Plaid::Configuration::Environment['sandbox'], configuration
    end

    test 'initializes with correct environment in production' do
      Rails.env.stubs(:production?).returns(true)

      configuration = nil
      Plaid::Configuration.any_instance.stubs(:server_index=).with do |index|
        configuration = index
        true
      end

      PlaidServices::Api.new
      assert_equal Plaid::Configuration::Environment['production'], configuration
    end
  end
end
