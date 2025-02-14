# frozen_string_literal: true

# == Schema Information
#
# Table name: plaid_item_audits
#
#  id                    :bigint           not null, primary key
#  user_id               :bigint
#  item_id               :string
#  institution_id        :string
#  billed_products       :text             default([]), is an Array
#  products              :text             default([]), is an Array
#  consented_data_scopes :text             default([]), is an Array
#  audit_created_at      :datetime         not null
#  audit_op              :string           not null
#
module Plaid
  class ItemAudit < ApplicationRecord
    self.table_name = 'plaid_item_audits'

    enum :audit_op, {
      created: 'created',
      modified: 'modified',
      deleted: 'deleted'
    }
  end
end
