# frozen_string_literal: true

class AppProxyController < ApplicationController
  include ShopifyApp::AppProxyVerification

  def index
    shop = Shop.find_by(shopify_domain: params[:shop])
    redirect_to '/', allow_other_host: true and return unless shop.present?

    redirect_to "https://#{shop.shopify_domain}/a/trial/returns/search", allow_other_host: true
  end
end
