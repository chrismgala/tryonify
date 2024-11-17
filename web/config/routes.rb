# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  root to: "home#index"

  mount ShopifyApp::Engine, at: "/api"
  get "/api", to: redirect(path: "/") # Needed because our engine root is /api but that breaks FE routing

  if Rails.env.production?
    Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
      # Protect against timing attacks:
      # - See https://codahale.com/a-lesson-in-timing-attacks/
      # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
      # - Use & (do not use &&) so that it doesn't short circuit.
      # - Use digests to stop length information leaking (see also ActiveSupport::SecurityUtils.variable_size_secure_compare)
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username),
        ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
        ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password),
          ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
    end
  end
  mount Sidekiq::Web => "/sidekiq"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :selling_plan_groups, except: [:edit] do
        resources :products, controller: "selling_plan_products", only: [:index, :create]
      end
      resources :products, only: [:index]
      resources :orders, only: [:index, :show, :update]
      resources :draft_orders, only: [:index]
      resources :checkouts, only: [:index, :create] do
        collection do
          post :bulk_destroy
        end
      end
      resources :returns, only: [:index, :update, :destroy]
      resources :validations, only: [:index]

      get "/chart", to: "chart#index"

      # Current shop endpoint
      resource :shop, only: [:show, :update]

      # RecurringBillingCharge endpoint
      resource :billing, only: [:create, :show]

      get "/slack", to: "slack#index"
    end
  end

  namespace :app_proxy do
    root action: "index"

    resources :returns, only: [:index, :create] do
      get "search", on: :collection
    end

    # simple routes without a specified controller will go to AppProxyController

    # more complex routes will go to controllers in the AppProxy namespace
    #   resources :reviews
    # GET /app_proxy/reviews will now be routed to
    # AppProxy::ReviewsController#index, for example
  end

  # Any other routes will just render the react app
  match "*path" => "home#index", via: [:get, :post]
end
