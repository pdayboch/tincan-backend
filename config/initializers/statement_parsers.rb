# frozen_string_literal: true

# Auto require all statement parsers as they are
# necessary for the accounts/supported endpoint to
# function correctly

# Require the base class first
require_dependency Rails.root.join('app/services/statement_parser/base.rb')

Dir[Rails.root.join('app/services/statement_parser/*.rb')].each do |file|
  require_dependency file unless file.end_with?('base.rb')
end
