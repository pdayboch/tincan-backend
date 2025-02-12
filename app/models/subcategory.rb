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
class Subcategory < ApplicationRecord
  belongs_to :category
  has_many :transactions, dependent: :restrict_with_exception

  validates :name, presence: true
end
