class RemoveUniqueIndexFromSubcategoriesName < ActiveRecord::Migration[7.2]
  def change
    remove_index :subcategories, :name, unique: true
  end
end
