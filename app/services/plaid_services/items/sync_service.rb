# frozen_string_literal: true

module PlaidServices
  module Items
    class SyncService
      def initialize(item)
        @item = item
        check_params!
      end

      def call(plaid_item_data)
        update_data = update_data(plaid_item_data)
        @item.update(update_data)
      end

      private

      def update_data(data)
        update_data = {
          billed_products: data.billed_products,
          products: data.products
        }

        return update_data if @item.institution_id == data.institution_id

        institution_data = institution_details(data.institution_id)
        update_data.merge(institution_data)
      end

      def institution_details(institution_id)
        institution_data = PlaidServices::Api.institution_get(institution_id)
                                             .institution
        {
          institution_id: institution_id,
          institution_name: institution_data.name
        }
      end

      def check_params!
        error_msg = "plaid_item must be of type PlaidItem: #{@item.class}"
        raise ArgumentError, error_msg unless @item.instance_of? PlaidItem
      end
    end
  end
end
