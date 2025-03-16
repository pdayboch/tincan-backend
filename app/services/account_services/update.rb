# frozen_string_literal: true

module AccountServices
  class Update
    class ManualProviderNullificationError < StandardError
      def message
        'Cannot nullify manual account provider on a manual account'
      end
    end

    def initialize(account, params)
      @account = account
      @account_provider = if params.key?(:manual_account_provider)
                            params[:manual_account_provider]
                          else
                            :not_provided
                          end
      @user_id = params[:user_id]
      @active = params[:active].nil? ? nil : params[:active]
    end

    def call
      update_attributes = account_provider_attributes
      update_attributes['user_id'] = @user_id if @user_id.present?
      update_attributes['active'] = @active unless @active.nil?

      @account.assign_attributes(update_attributes)

      raise UnprocessableEntityError, @account.errors unless @account.save

      @account
    end

    private

    def account_provider_attributes
      return {} if @account_provider == :not_provided

      if @account_provider.nil?
        raise ManualProviderNullificationError if @account.plaid_account_id.blank?

        return { parser_class: nil }
      end

      parser_class_attributes
    end

    def parser_class_attributes
      parser_class = SupportedAccountsEntity.class_from_provider(@account_provider)

      attributes = { parser_class: @account_provider }

      return attributes if @account.plaid_account_id.present?

      attributes.merge(
        institution_name: parser_class::INSTITUTION_NAME,
        name: parser_class::ACCOUNT_NAME,
        account_type: parser_class::ACCOUNT_TYPE,
        account_subtype: parser_class::ACCOUNT_SUBTYPE
      )
    end
  end
end
