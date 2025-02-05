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
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'should not save duplicate email' do
    user = users(:one)
    another_user = User.new(
      name: 'another name',
      email: user.email,
      password: 'another pass'
    )

    assert_not another_user.valid?, 'Duplicate email should not be valid'
    assert_includes another_user.errors[:email], 'already exists'
  end

  test 'should not save duplicate email case insensitive' do
    user = users(:one)
    another_user = User.new(
      name: 'another name',
      email: user.email.upcase,
      password: 'another pass'
    )

    assert_not another_user.valid?, 'Duplicate email should not be valid'
    assert_includes another_user.errors[:email], 'already exists'
  end

  test 'should create a non-deletable cash account upon creation' do
    user = User.create(
      name: 'name',
      email: 'test@email.com',
      password: 'pass'
    )

    cash_account = user.accounts.find_by(name: 'Cash')

    assert_not_nil cash_account, 'Cash account not created on User creation'
    assert_not cash_account.deletable, 'Cash account marked as deletable'
    assert_equal '-', cash_account.institution_name
    assert_equal 'assets', cash_account.account_type
    assert_equal 'cash', cash_account.account_subtype
  end

  test 'should mark all accounts as deletable before user is destroyed' do
    user = users(:one)
    account = user.accounts.create!(institution_name: 'Chase', name: 'Savings', account_type: 'savings',
                                    deletable: false)

    PlaidItem.any_instance.stubs(:remove_item_from_plaid).returns(true)
    user.destroy

    assert_raises(ActiveRecord::RecordNotFound) { account.reload }
  end
end
