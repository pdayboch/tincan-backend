# frozen_string_literal: true

class CategorizationJobsController < ApplicationController
  def create
    # TODO: Add rate limit of 1 job per minute and smart logic to check
    # if any new rules were added since it was last executed or any
    # uncategorized transactions added since job last executed.
    CategorizeTransactionsJob.perform_async
    render json: { accepted: 'success' }, status: :accepted
  end
end
