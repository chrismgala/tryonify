# frozen_string_literal: true

class Shop < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorageWithScopes

  has_many :orders, dependent: :destroy
  has_many :returns, dependent: :destroy
  has_many :selling_plan_groups, dependent: :destroy
  has_many :checkouts, dependent: :destroy
  has_many :metafields, dependent: :destroy
  has_many :bulk_operations, dependent: :destroy

  def api_version
    ShopifyApp.configuration.api_version
  end

  def get_metafield(key)
    metafields.find_by(key:)
  end
end
