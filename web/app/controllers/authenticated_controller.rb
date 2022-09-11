# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  include ShopifyApp::Authenticated

  private

  def current_user
    Shop.find_by(shopify_domain: current_shopify_session.shop)
  end
end
