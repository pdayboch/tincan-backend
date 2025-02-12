# frozen_string_literal: true

# Default Categories and Subcategories for Production and Development
default_categories = {
  'Auto & Transport' => {
    type: 'spend',
    subcategories: ['Auto Insurance', 'Auto Payment', 'Gas & Fuel',
                    'Parking', 'Public Transportation', 'Ride Share',
                    'Service & Auto Parts', 'Tolls']
  },
  'Bills & Utilities' => {
    type: 'spend',
    subcategories: ['Internet', 'Phone', 'Television', 'Utilities']
  },
  'Business Services' => {
    type: 'spend',
    subcategories: ['Financial Services', 'Office Supplies', 'Printing',
                    'Shipping']
  },
  'Childcare' => {
    type: 'spend',
    subcategories: ['Child Activities', 'Clothing', 'Daycare',
                    'Feeding', 'Supplies']
  },
  'Education' => {
    type: 'spend',
    subcategories: ['Books & Supplies', 'Room & Board', 'Tuition']
  },
  'Entertainment' => {
    type: 'spend',
    subcategories: ['Arts', 'Entertainment', 'Gambling', 'Games',
                    'Music', 'Movies & DVDs', 'Newspapers & Magazines',
                    'Outdoors']
  },
  'Fees & Charges' => {
    type: 'spend',
    subcategories: ['ATM Fee', 'Service Fee']
  },
  'Food' => {
    type: 'spend',
    subcategories: ['Alcohol & Bars', 'Coffee Shops', 'Fast Food',
                    'Food', 'Food Delivery', 'Groceries', 'Restaurants']
  },
  'Gifts & Donations' => {
    type: 'spend',
    subcategories: ['Donation', 'Family', 'Gift']
  },
  'Health & Fitness' => {
    type: 'spend',
    subcategories: ['Dentist', 'Doctor', 'Gym', 'Optometrist',
                    'Pharmacy', 'Sports', 'Veterinary']
  },
  'Home' => {
    type: 'spend',
    subcategories: ['Furnishings', 'Home Improvement', 'Rent & Mortgage',
                    'Security']
  },
  'Personal Care' => {
    type: 'spend',
    subcategories: ['Hair', 'Laundry', 'Spa & Massage']
  },
  'Shopping' => {
    type: 'spend',
    subcategories: ['Books', 'Clothing', 'Electronics & Software',
                    'Pet Food & Supplies', 'Shopping', 'Sporting Goods']
  },
  'Taxes' => {
    type: 'spend',
    subcategories: ['Federal Tax', 'State Tax', 'Tax Prep']
  },
  'Travel' => {
    type: 'spend',
    subcategories: ['Air Fare', 'Ferry Fare', 'Hotel', 'Rental Car & Taxi',
                    'Train Fare', 'Vacation']
  },
  'Income' => {
    type: 'income',
    subcategories: ['Dividend', 'Income', 'Interest', 'Paycheck', 'Pension',
                    'Rebates', 'Unemployment']
  },
  'Investments' => {
    type: 'transfer',
    subcategories: ['Buy', 'Sell']
  },
  'Transfer' => {
    type: 'transfer',
    subcategories: ['Cash & ATM', 'Credit Card Payment', 'Transfer']
  },
  'Uncategorized' => {
    type: 'spend',
    subcategories: ['Uncategorized']
  }
}

default_categories.each do |category, data|
  c = Category.find_or_create_by!(name: category, category_type: data[:type])
  data[:subcategories].each do |subcategory|
    c.subcategories.find_or_create_by!(name: subcategory)
  end
end
