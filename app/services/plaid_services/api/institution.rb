# frozen_string_literal: true

module PlaidServices
  class Api
    module Institution
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def institution_get(institution_id)
          request = {
            institution_id: institution_id,
            country_codes: %w[US GB CA]
          }

          new.institution_get(request)
        end
      end

      def institution_get(request)
        req = Plaid::InstitutionsGetByIdRequest.new(request)
        @client.institutions_get_by_id(req)
      rescue Plaid::ApiError => e
        Api.log_plaid_error(e)
        raise e
      end
    end
  end
end
