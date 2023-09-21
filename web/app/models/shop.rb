# frozen_string_literal: true

class Shop < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorageWithScopes

  has_many :orders, dependent: :destroy
  has_many :returns, dependent: :destroy
  has_many :selling_plan_groups, dependent: :destroy
  has_many :checkouts, dependent: :destroy
  has_many :metafields, dependent: :destroy
  has_many :bulk_operations, dependent: :destroy

  APPROVED_FOR_PREPAID = [
    "fd4267.myshopify.com",
    "camplane.myshopify.com",
    "hello-lashesnz.myshopify.com",
    "theluxelend.myshopify.com"
  ].freeze

  def api_version
    ShopifyApp.configuration.api_version
  end

  def cancel_prepaid_cards
    return self[:cancel_prepaid_cards] if !Rails.env.production? || APPROVED_FOR_PREPAID.include?(shopify_domain)
    false
  end

  def get_metafield(key)
    metafields.find_by(key:)
  end
end
