# frozen_string_literal: true

module AccountServices
  class Update
    def initialize(account, params)
      @account = account
      @account_provider = params[:manual_account_provider]
      @user_id = params[:user_id]
      @active = params[:active].nil? ? nil : params[:active]
    end

    def call
      update_attributes = {}
      update_attributes.merge!(parser_class_attributes) if @account_provider.present?
      update_attributes['user_id'] = @user_id if @user_id.present?
      update_attributes['active'] = @active unless @active.nil?

      @account.assign_attributes(update_attributes)

      raise UnprocessableEntityError, @account.errors unless @account.save

      @account
    end

    private

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
