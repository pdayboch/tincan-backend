# frozen_string_literal: true

class SupportedAccountsEntity
  def data
    StatementParser::Base.descendants.map do |parser_class|
      {
        accountProvider: SupportedAccountsEntity.provider_from_class(parser_class),
        institutionName: parser_class::INSTITUTION_NAME,
        accountName: parser_class::ACCOUNT_NAME,
        accountType: parser_class::ACCOUNT_TYPE,
        accountSubtype: parser_class::ACCOUNT_SUBTYPE
      }
    end
  end

  def self.provider_from_class(klass)
    klass.name.split('::')[1]
  end

  def self.class_from_provider(provider)
    raise EmptyProviderError, 'provider cannot be nil' unless provider

    # Ensure provider starts with an uppercase letter
    raise InvalidParserError, provider if provider !~ /^[A-Z]/

    class_name = "StatementParser::#{provider}"
    raise InvalidParserError, provider unless Object.const_defined?(class_name)

    class_name.constantize
  end
end
