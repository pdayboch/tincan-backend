# frozen_string_literal: true

ActiveRecord::Base.logger.level = Logger::INFO if Rails.env.development?
