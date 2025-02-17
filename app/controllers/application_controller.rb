# frozen_string_literal: true

class ApplicationController < ActionController::API
  before_action :transform_camel_case_params

  rescue_from UnprocessableEntityError do |e|
    render json: { errors: e.errors }, status: :unprocessable_entity
  end

  rescue_from BadRequestError do |e|
    render json: { errors: e.errors }, status: :bad_request
  end

  private

  # Transform camelCase params to snake_case
  def transform_camel_case_params
    params.deep_transform_keys! { |key| key.to_s.underscore }
  end
end
