# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  namespace :api do
    namespace :v1 do
      post '/plaid/create-link-token', to: 'plaid#create_link_token'
      post '/plaid/set-access-token', to: 'plaid#set_access_token'
    end
  end

  resources :transactions, only: %i[index create update destroy] do
    member do
      get :splits, to: 'transactions/splits#show'
      patch 'sync-splits', to: 'transactions/splits#sync'
    end
  end

  resources :accounts, only: %i[index create update destroy] do
    collection do
      get :supported, to: 'supported_accounts#index'
    end
  end

  resources :users, only: %i[index create update destroy]
  resources :subcategories, only: %i[create update destroy]
  resources :categories, only: %i[index create update destroy]

  namespace :categorization do
    resources :conditions, only: %i[index create update destroy]
    resources :rules, only: %i[index create update destroy]
  end

  post 'categorization-jobs', to: 'categorization_jobs#create'

  resources :trends, only: [] do
    collection do
      get 'overTime', to: 'trends#over_time'
    end
  end
end
