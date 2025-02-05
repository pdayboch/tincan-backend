# frozen_string_literal: true

require 'test_helper'

module Plaid
  class AccountTypeMapperTest < ActiveSupport::TestCase
    test 'maps depository accounts to assets with cash subtype' do
      assert_equal({ type: 'assets', subtype: 'cash' }, AccountTypeMapper.map('depository'))
    end

    test 'maps investment accounts to assets with investments subtype' do
      assert_equal({ type: 'assets', subtype: 'investments' }, AccountTypeMapper.map('investment'))
    end

    test 'maps credit accounts to liabilities with credit cards subtype' do
      assert_equal({ type: 'liabilities', subtype: 'credit cards' }, AccountTypeMapper.map('credit'))
    end

    test 'maps loan accounts to liabilities with loans subtype' do
      assert_equal({ type: 'liabilities', subtype: 'loans' }, AccountTypeMapper.map('loan'))
    end

    test 'maps other accounts to assets with other subtype' do
      assert_equal({ type: 'assets', subtype: 'other' }, AccountTypeMapper.map('other'))
    end

    test 'raises error for unknown account type' do
      assert_raises(AccountTypeMapper::InvalidAccountType) do
        AccountTypeMapper.map('unknown')
      end
    end

    test 'handles case-insensitive input' do
      assert_equal(
        { type: 'assets', subtype: 'cash' }, AccountTypeMapper.map('DEPOSITORY')
      )
    end
  end
end
