# frozen_string_literal: true

module Api
  module V1
    class PlaidController < ApplicationController
      def create_link_token
        # TODO: Auth: convert to current user
        user = User.find_by(id: params[:user_id])
        return render status: :forbidden unless user

        link_token = PlaidServices::Api.create_link_token(user)
        render json: { linkToken: link_token }
      rescue Plaid::ApiError
        render json: { error: 'Invalid request' }, status: :bad_request
      end

      def set_access_token
        # TODO: Auth: convert to current user
        user = User.find_by(id: params[:user_id])
        return render status: :forbidden unless user

        err_msg = 'publicToken is required'
        raise BadRequestError.new(public_token: [err_msg]) unless params[:public_token]

        result = PlaidServices::ItemCreate.new(params[:public_token], user).call
        render json: { status: result }
      rescue Plaid::ApiError
        render json: { error: 'Invalid request' }, status: :bad_request
      end
    end
  end
end
