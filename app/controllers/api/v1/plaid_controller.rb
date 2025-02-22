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

        err_msg = 'is required'
        raise BadRequestError.new(public_token: [err_msg]) unless params[:public_token]

        job_id = PlaidServices::Items::CreateService.new(params[:public_token], user).call
        render json: { jobId: job_id }
      rescue Plaid::ApiError
        render json: { error: 'Invalid request' }, status: :bad_request
      end

      # GET /plaid/item-initialization-job-statuses
      def item_initialization_job_status
        # TODO: Auth: ensure user has access to that job
        # TODO: Auth: return 404 if job isn't found or user doesn't have access.
        err_msg = 'is required'
        raise BadRequestError.new(job_id: [err_msg]) unless params[:job_id]

        status = PlaidServices::ItemInitializationJobStatusService.new(
          params[:job_id]
        ).call

        render json: { status: status }
      end
    end
  end
end
