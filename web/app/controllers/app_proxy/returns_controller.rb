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
        order = service.order
        existing_order = Order.find_by!(shopify_id: order.dig("id"))

        @return_order = {
          id: order.dig("id"),
          name: order.dig("name"),
          financial_status: order.dig("displayFinancialStatus"),
          due_at: order.dig("paymentTerms", "paymentSchedules", "nodes", 0, "dueAt"),
          fulfillments: [],
          line_items: order.dig("lineItems", "edges").map do |edge|
            next if edge.dig("node", "unfulfilledQuantity") == 0

            {
              id: edge.dig("node", "id"),
              selling_plan_id: edge.dig("node", "sellingPlan", "sellingPlanId"),
              title: edge.dig("node", "title"),
              variant_title: edge.dig("node", "variantTitle"),
              image_url: edge.dig("node", "image", "url"),
              unfulfilled_quantity: edge.dig("node", "unfulfilledQuantity"),
              quantity: edge.dig("node", "quantity"),
            }
          end.compact
        }

        order.dig('fulfillments').each do |edge|
          edge.dig('fulfillmentLineItems', 'edges').each do |fulfillment_edge|
            next if existing_order.returns.each do |return_item|
              return_item.return_line_items.find {|x| x.fulfillment_line_item_id == fulfillment_edge.dig('node', 'id')}
            end
            @return_order[:fulfillments] << {
              id: fulfillment_edge.dig('node', 'id'),
              quantity: fulfillment_edge.dig('node', 'quantity'),
              line_item: {
                id: fulfillment_edge.dig('node', 'lineItem', 'id'),
                title: fulfillment_edge.dig('node', 'lineItem', 'title'),
                variant_title: fulfillment_edge.dig('node', 'lineItem', 'variantTitle'),
                image_url: fulfillment_edge.dig('node', 'lineItem', 'image', 'url'),
                selling_plan_id: fulfillment_edge.dig('node', 'lineItem', 'sellingPlan', 'sellingPlanId'),
              }
            }
          end
        end
        
        render(layout: false, content_type: "application/liquid")
      else
        redirect_to("/a/trial/returns/search?err=not_found", allow_other_hosts: true)
      end
    end
  end

  def create
    order = Order.find_by(shopify_id: return_params[:order_id])

    current_shop.with_shopify_session do
      Shopify::Returns::Create.call(
        order_id: return_params[:order_id],
        line_items: [
          fulfillmentLineItemId: return_params[:fulfillment_line_item_id],
          quantity: return_params[:quantity].to_i,
        ],
      )
    end

    redirect_to("/a/trial/returns?name=#{CGI.escape(order.name)}&email=#{CGI.escape(order.email)}")
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
      :fulfillment_line_item_id,
      :quantity,
    )
  end
end
