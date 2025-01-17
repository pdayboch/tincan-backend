# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  name            :string
#  email           :string
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class User < ApplicationRecord
  has_secure_password
  has_many :accounts, dependent: :destroy
  has_many :plaid_items, dependent: :destroy

  after_create :create_cash_account

  # Ensure this executes before trying to destroy anthing.
  before_destroy :make_accounts_deletable,
                 prepend: true

  validates :email,
            presence: true,
            uniqueness: {
              case_sensitive: false,
              message: 'already exists'
            }

  private

  def create_cash_account
    accounts.create!(
      name: 'Cash',
      account_type: 'cash',
      deletable: false
    )
  end

  def make_accounts_deletable
    accounts.each do |account|
      account.update(deletable: true)
    end
  end
end
