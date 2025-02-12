# frozen_string_literal: true

# == Schema Information
#
# Table name: subcategories
#
#  id          :bigint           not null, primary key
#  name        :string
#  category_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'test_helper'

class SubcategoryTest < ActiveSupport::TestCase
  test 'should not create subcategory with empty name' do
    category = categories(:spend)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      Subcategory.create!(category_id: category.id, name: '')
    end

    assert_equal  "Validation failed: Name can't be blank", error.message
  end

  test 'should not update subcategory with empty name' do
    subcategory = subcategories(:restaurant)
    error = assert_raises(ActiveRecord::RecordInvalid) do
      subcategory.update!(name: '')
    end

    assert_equal "Validation failed: Name can't be blank", error.message
  end

  test 'should not delete subcategory with transactions' do
    subcategory = subcategories(:paycheck)
    assert_not subcategory.transactions.empty?, 'Subcategory should have transactions for this test'

    assert_raises ActiveRecord::DeleteRestrictionError do
      subcategory.destroy
    end

    assert Subcategory.exists?(subcategory.id), 'Subcategory should still exist after attempting to delete'
  end
end
