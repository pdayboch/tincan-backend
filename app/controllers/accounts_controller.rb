# frozen_string_literal: true

class AccountsController < ApplicationController
  # GET /accounts
  def index
    user_ids = params[:userIds]
    account_types = params[:accountTypes]

    data = AccountDataEntity.new(
      user_ids: user_ids,
      account_types: account_types
    ).data

    render json: data
  end

  # POST /accounts
  # API for creating manual accounts only. Plaid accounts are created via Plaid
  # Link which then get synced via Plaid::SyncAccountsJob
  def create
    account = AccountServices::Create.new(account_params).call
    render json: account, status: :created, location: account
  rescue InvalidParserError => e
    error = {
      manual_account_provider: ["'#{e.message}' is not a valid value."]
    }
    raise UnprocessableEntityError, error
  rescue EmptyProviderError
    error = {
      manual_account_provider: ['cannot be empty']
    }
    raise UnprocessableEntityError, error
  end

  # PATCH/PUT /accounts/1
  def update
    account = Account.find(params[:id])
    updated_account = AccountServices::Update.new(account, account_params).call

    render json: updated_account
  rescue InvalidParserError => e
    error = {
      manual_account_provider: ["'#{e.message}' is not a valid value."]
    }
    raise UnprocessableEntityError, error
  rescue AccountServices::Update::ManualProviderNullificationError
    error = {
      manual_account_provider: ['cannot be removed from a manual account.']
    }
    raise UnprocessableEntityError, error
  end

  # DELETE /accounts/1
  def destroy
    account = Account.find(params[:id])
    if account.plaid_account_id.present?
      raise BadRequestError, { account: ['Plaid accounts cannot be deleted at this time'] }
    end

    account.destroy!
  end

  private

  def account_params
    params.permit(:active, :manual_account_provider, :user_id)
  end
end
