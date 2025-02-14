# frozen_string_literal: true

# == Schema Information
#
# Table name: plaid_items
#
#  id                      :bigint           not null, primary key
#  user_id                 :bigint           not null
#  access_key              :string           not null
#  item_id                 :string
#  institution_id          :string
#  transaction_sync_cursor :string
#  transactions_synced_at  :datetime
#  accounts_synced_at      :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  institution_name        :string
#  billed_products         :text             default([]), is an Array
#  products                :text             default([]), is an Array
#  consented_data_scopes   :text             default([]), is an Array
#
class PlaidItem < ApplicationRecord
  belongs_to :user
  has_many :accounts, dependent: :nullify

  after_create :create_audit_record
  after_update :update_audit_record
  before_destroy :remove_item_from_plaid
  after_destroy :destroy_audit_record

  AUDITED_ATTRS = %w[
    user_id
    item_id
    institution_id
    billed_products
    products
    consented_data_scopes
  ].freeze

  ITEM_NOT_FOUND_ERROR = 'ITEM_NOT_FOUND'

  def mark_accounts_as_synced
    update(accounts_synced_at: Time.zone.now)
  end

  def mark_transactions_as_synced
    update(transactions_synced_at: Time.zone.now)
  end

  private

  def create_audit_record
    Plaid::ItemAudit.create!(
      user_id: user_id,
      item_id: item_id,
      institution_id: institution_id,
      billed_products: billed_products,
      products: products,
      consented_data_scopes: consented_data_scopes,
      audit_op: :created,
      audit_created_at: Time.current
    )
  end

  def update_audit_record
    # Only create audit record if tracked attributes changed
    return unless previous_changes.keys.intersect?(AUDITED_ATTRS)

    Plaid::ItemAudit.create!(
      user_id: user_id,
      item_id: item_id,
      institution_id: institution_id,
      billed_products: billed_products,
      products: products,
      consented_data_scopes: consented_data_scopes,
      audit_op: :modified,
      audit_created_at: Time.current
    )
  end

  def destroy_audit_record
    Plaid::ItemAudit.create!(
      user_id: user_id,
      item_id: item_id,
      institution_id: institution_id,
      billed_products: billed_products,
      products: products,
      consented_data_scopes: consented_data_scopes,
      audit_op: :deleted,
      audit_created_at: Time.current
    )
  end

  def remove_item_from_plaid
    PlaidServices::Api.new(access_key).destroy
  rescue Plaid::ApiError => e
    return true if e.data['error_code'] == ITEM_NOT_FOUND_ERROR

    raise e
  end
end
