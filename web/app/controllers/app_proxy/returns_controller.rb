# frozen_string_literal: true

class AppProxy::ReturnsController < ApplicationController
  include ShopifyApp::AppProxyVerification

  before_action :current_shop

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to("/a/trial/returns/search?err=not_found", allow_other_hosts: true)
  end

  def index
    redirect_to("https://#{params[:shop]}", allow_other_hosts: true) and return unless current_shop.access_scopes.include?('write_returns')

    @shop.with_shopify_session do
      service = SearchOrder.new("(name:#{order_params[:name]}) AND (email:#{order_params[:email]}")
      service.call

      if service.order
        @order = Order.find_by!(shopify_id: service.order.dig("id"))
        @fulfillments = service.order.dig('fulfillments')

        render(layout: false, content_type: "application/liquid")
      else
        redirect_to("/a/trial/returns/search?err=not_found", allow_other_hosts: true)
      end
    end
  end

  def create
    order = Order.find_by(shopify_id: return_params[:order_id])

    current_shop.with_shopify_session do
      response = Shopify::Returns::Create.call(
        order_id: return_params[:order_id],
        line_items: return_params[:return_line_items]
      )

      return_item = Return.find_or_create_by!(shopify_id: response.body.dig("data", "returnCreate", "return", "id")) do |return_item|
        return_item.shop = current_shop
        return_item.order = order
        return_item.status = response.body.dig("data", "returnCreate", "return", "status").downcase
        return_item.return_line_items = response.body.dig("data", "returnCreate", "return", "returnLineItems", "edges").map do |edge|
          line_item = LineItem.find_by!(shopify_id: edge.dig("node", "fulfillmentLineItem", "lineItem", "id"))
          ReturnLineItem.new(
            line_item: line_item,
            shopify_id: edge.dig("node", "id"),
            fulfillment_line_item_id: edge.dig("node", "fulfillmentLineItem", "id"),
            quantity: edge.dig("node", "quantity").to_i
          )
        end
      end
  
      json render: return_item
    end
  end

  def search
    @error = params[:err]
    render(layout: false, content_type: "application/liquid")
  end

  private

  def current_shop
    @shop ||= Shop.find_by(shopify_domain: params[:shop])
  end

  def order_params
    params.permit(
      :name,
      :email
    )
  end

  def return_params
    params.permit(
      :order_id,
      :return_reason,
      :return_reason_note,
      return_line_items: [
        :line_item_id,
        :fulfillment_line_item_id,
        :quantity,
      ]
    )
  end
end
