# frozen_string_literal: true

module Plaid
  class CategoryMapper
    CATEGORY_MAPPING = {
      'INCOME_DIVIDENDS' => %w[Income Dividend],
      'INCOME_INTEREST_EARNED' => %w[Income Interest],
      'INCOME_RETIREMENT_PENSION' => %w[Income Pension],
      'INCOME_TAX_REFUND' => ['Taxes', 'Federal Tax'],
      'INCOME_UNEMPLOYMENT' => %w[Income Unemployment],
      'INCOME_WAGES' => %w[Income Paycheck],
      'INCOME_OTHER_INCOME' => %w[Income Income],
      'TRANSFER_IN_CASH_ADVANCES_AND_LOANS' => %w[Transfer Transfer],
      'TRANSFER_IN_DEPOSIT' => %w[Transfer Transfer],
      'TRANSFER_IN_INVESTMENT_AND_RETIREMENT_FUNDS' => %w[Transfer Transfer],
      'TRANSFER_IN_SAVINGS' => %w[Transfer Transfer],
      'TRANSFER_IN_ACCOUNT_TRANSFER' => %w[Transfer Transfer],
      'TRANSFER_IN_OTHER_TRANSFER_IN' => %w[Transfer Transfer],
      'TRANSFER_OUT_INVESTMENT_AND_RETIREMENT_FUNDS' => %w[Transfer Transfer],
      'TRANSFER_OUT_SAVINGS' => %w[Transfer Transfer],
      'TRANSFER_OUT_WITHDRAWAL' => %w[Transfer Transfer],
      'TRANSFER_OUT_ACCOUNT_TRANSFER' => %w[Transfer Transfer],
      'TRANSFER_OUT_OTHER_TRANSFER_OUT' => %w[Transfer Transfer],
      'LOAN_PAYMENTS_CAR_PAYMENT' => ['Auto & Transport', 'Auto Payment'],
      'LOAN_PAYMENTS_CREDIT_CARD_PAYMENT' => ['Transfer', 'Credit Card Payment'],
      'LOAN_PAYMENTS_PERSONAL_LOAN_PAYMENT' => %w[Transfer Transfer],
      'LOAN_PAYMENTS_MORTGAGE_PAYMENT' => ['Home', 'Rent & Mortgage'],
      'LOAN_PAYMENTS_STUDENT_LOAN_PAYMENT' => %w[Transfer Transfer],
      'LOAN_PAYMENTS_OTHER_PAYMENT' => %w[Transfer Transfer],
      'BANK_FEES_ATM_FEES' => ['Fees & Charges', 'ATM Fee'],
      'BANK_FEES_FOREIGN_TRANSACTION_FEES' => ['Fees & Charges', 'Service Fee'],
      'BANK_FEES_INSUFFICIENT_FUNDS' => ['Fees & Charges', 'Service Fee'],
      'BANK_FEES_INTEREST_CHARGE' => ['Fees & Charges', 'Service Fee'],
      'BANK_FEES_OVERDRAFT_FEES' => ['Fees & Charges', 'Service Fee'],
      'BANK_FEES_OTHER_BANK_FEES' => ['Fees & Charges', 'Service Fee'],
      'ENTERTAINMENT_CASINOS_AND_GAMBLING' => %w[Entertainment Gambling],
      'ENTERTAINMENT_MUSIC_AND_AUDIO' => %w[Entertainment Music],
      'ENTERTAINMENT_SPORTING_EVENTS_AMUSEMENT_PARKS_AND_MUSEUMS' => %w[Entertainment Entertainment],
      'ENTERTAINMENT_TV_AND_MOVIES' => ['Entertainment', 'Movies & DVDs'],
      'ENTERTAINMENT_VIDEO_GAMES' => %w[Entertainment Games],
      'ENTERTAINMENT_OTHER_ENTERTAINMENT' => %w[Entertainment Entertainment],
      'FOOD_AND_DRINK_BEER_WINE_AND_LIQUOR' => ['Food', 'Alcohol & Bars'],
      'FOOD_AND_DRINK_COFFEE' => ['Food', 'Coffee Shops'],
      'FOOD_AND_DRINK_FAST_FOOD' => ['Food', 'Fast Food'],
      'FOOD_AND_DRINK_GROCERIES' => %w[Food Groceries],
      'FOOD_AND_DRINK_RESTAURANT' => %w[Food Restaurants],
      'FOOD_AND_DRINK_VENDING_MACHINES' => ['Food', 'Fast Food'],
      'FOOD_AND_DRINK_OTHER_FOOD_AND_DRINK' => %w[Food Food],
      'GENERAL_MERCHANDISE_BOOKSTORES_AND_NEWSSTANDS' => %w[Uncategorized Uncategorized],
      'GENERAL_MERCHANDISE_CLOTHING_AND_ACCESSORIES' => %w[Shopping Clothing],
      'GENERAL_MERCHANDISE_CONVENIENCE_STORES' => %w[Uncategorized Uncategorized],
      'GENERAL_MERCHANDISE_DEPARTMENT_STORES' => %w[Shopping Clothing],
      'GENERAL_MERCHANDISE_DISCOUNT_STORES' => %w[Uncategorized Uncategorized],
      'GENERAL_MERCHANDISE_ELECTRONICS' => ['Shopping', 'Electronics & Software'],
      'GENERAL_MERCHANDISE_GIFTS_AND_NOVELTIES' => %w[Uncategorized Uncategorized],
      'GENERAL_MERCHANDISE_OFFICE_SUPPLIES' => ['Business Services', 'Office Supplies'],
      'GENERAL_MERCHANDISE_ONLINE_MARKETPLACES' => %w[Uncategorized Uncategorized],
      'GENERAL_MERCHANDISE_PET_SUPPLIES' => ['Shopping', 'Pet Food & Supplies'],
      'GENERAL_MERCHANDISE_SPORTING_GOODS' => ['Shopping', 'Sporting Goods'],
      'GENERAL_MERCHANDISE_SUPERSTORES' => %w[Uncategorized Uncategorized],
      'GENERAL_MERCHANDISE_TOBACCO_AND_VAPE' => %w[Uncategorized Uncategorized],
      'GENERAL_MERCHANDISE_OTHER_GENERAL_MERCHANDISE' => %w[Uncategorized Uncategorized],
      'HOME_IMPROVEMENT_FURNITURE' => %w[Home Furnishings],
      'HOME_IMPROVEMENT_HARDWARE' => ['Home', 'Home Improvement'],
      'HOME_IMPROVEMENT_REPAIR_AND_MAINTENANCE' => ['Home', 'Home Improvement'],
      'HOME_IMPROVEMENT_SECURITY' => %w[Home Security],
      'HOME_IMPROVEMENT_OTHER_HOME_IMPROVEMENT' => ['Home', 'Home Improvement'],
      'MEDICAL_DENTAL_CARE' => ['Health & Fitness', 'Dentist'],
      'MEDICAL_EYE_CARE' => ['Health & Fitness', 'Optometrist'],
      'MEDICAL_NURSING_CARE' => ['Health & Fitness', 'Doctor'],
      'MEDICAL_PHARMACIES_AND_SUPPLEMENTS' => ['Health & Fitness', 'Pharmacy'],
      'MEDICAL_PRIMARY_CARE' => ['Health & Fitness', 'Doctor'],
      'MEDICAL_VETERINARY_SERVICES' => ['Health & Fitness', 'Veterinary'],
      'MEDICAL_OTHER_MEDICAL' => ['Health & Fitness', 'Doctor'],
      'PERSONAL_CARE_GYMS_AND_FITNESS_CENTERS' => ['Health & Fitness', 'Gym'],
      'PERSONAL_CARE_HAIR_AND_BEAUTY' => ['Personal Care', 'Hair'],
      'PERSONAL_CARE_LAUNDRY_AND_DRY_CLEANING' => ['Personal Care', 'Laundry'],
      'PERSONAL_CARE_OTHER_PERSONAL_CARE' => %w[Uncategorized Uncategorized],
      'GENERAL_SERVICES_ACCOUNTING_AND_FINANCIAL_PLANNING' => ['Business Services', 'Financial Services'],
      'GENERAL_SERVICES_AUTOMOTIVE' => ['Auto & Transport', 'Service & Auto Parts'],
      'GENERAL_SERVICES_CHILDCARE' => %w[Childcare Daycare],
      'GENERAL_SERVICES_CONSULTING_AND_LEGAL' => %w[Uncategorized Uncategorized],
      'GENERAL_SERVICES_EDUCATION' => %w[Education Tuition],
      'GENERAL_SERVICES_INSURANCE' => %w[Uncategorized Uncategorized],
      'GENERAL_SERVICES_POSTAGE_AND_SHIPPING' => ['Business Services', 'Shipping'],
      'GENERAL_SERVICES_STORAGE' => %w[Uncategorized Uncategorized],
      'GENERAL_SERVICES_OTHER_GENERAL_SERVICES' => %w[Uncategorized Uncategorized],
      'GOVERNMENT_AND_NON_PROFIT_DONATIONS' => %w[Uncategorized Uncategorized],
      'GOVERNMENT_AND_NON_PROFIT_GOVERNMENT_DEPARTMENTS_AND_AGENCIES' => %w[Uncategorized Uncategorized],
      'GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT' => %w[Uncategorized Uncategorized],
      'GOVERNMENT_AND_NON_PROFIT_OTHER_GOVERNMENT_AND_NON_PROFIT' => %w[Uncategorized Uncategorized],
      'TRANSPORTATION_BIKES_AND_SCOOTERS' => %w[Uncategorized Uncategorized],
      'TRANSPORTATION_GAS' => ['Auto & Transport', 'Gas & Fuel'],
      'TRANSPORTATION_PARKING' => ['Auto & Transport', 'Parking'],
      'TRANSPORTATION_PUBLIC_TRANSIT' => ['Auto & Transport', 'Public Transportation'],
      'TRANSPORTATION_TAXIS_AND_RIDE_SHARES' => ['Auto & Transport', 'Ride Share'],
      'TRANSPORTATION_TOLLS' => ['Auto & Transport', 'Tolls'],
      'TRANSPORTATION_OTHER_TRANSPORTATION' => %w[Uncategorized Uncategorized],
      'TRAVEL_FLIGHTS' => ['Travel', 'Air Fare'],
      'TRAVEL_LODGING' => %w[Travel Hotel],
      'TRAVEL_RENTAL_CARS' => ['Travel', 'Rental Car & Taxi'],
      'TRAVEL_OTHER_TRAVEL' => %w[Uncategorized Uncategorized],
      'RENT_AND_UTILITIES_GAS_AND_ELECTRICITY' => ['Bills & Utilities', 'Utilities'],
      'RENT_AND_UTILITIES_INTERNET_AND_CABLE' => ['Bills & Utilities', 'Internet'],
      'RENT_AND_UTILITIES_RENT' => ['Home', 'Rent & Mortgage'],
      'RENT_AND_UTILITIES_SEWAGE_AND_WASTE_MANAGEMENT' => ['Bills & Utilities', 'Utilities'],
      'RENT_AND_UTILITIES_TELEPHONE' => ['Bills & Utilities', 'Phone'],
      'RENT_AND_UTILITIES_WATER' => ['Bills & Utilities', 'Utilities'],
      'RENT_AND_UTILITIES_OTHER_UTILITIES' => ['Bills & Utilities', 'Utilities']
    }.freeze

    def initialize
      load_categories
    end

    def map(plaid_category)
      category_name, subcategory_name = CATEGORY_MAPPING[plaid_category] ||
                                        %w[Uncategorized Uncategorized]

      category = @categories[category_name]
      subcategory = @subcategories["#{category_name}-#{subcategory_name}"]

      [category, subcategory]
    end

    private

    def load_categories
      categories = ::Category.includes(:subcategories).all

      @categories = {}
      @subcategories = {}

      categories.each do |category|
        @categories[category.name] = category
        category.subcategories.each do |subcategory|
          @subcategories["#{category.name}-#{subcategory.name}"] = subcategory
        end
      end
    end
  end
end
