# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  include ShopifyApp::EnsureHasSession

  private

  def current_user
    Shop.find_by(shopify_domain: current_shopify_session.shop)
  end
end
