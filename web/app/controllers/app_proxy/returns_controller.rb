class AppProxy::ReturnsController < ApplicationController
  include ShopifyApp::AppProxyVerification

  before_action :current_shop

  def index
    @shop.with_shopify_session do
      service = SearchOrder.new("(name:#{order_params[:name]}) AND (email:#{order_params[:email]}")
      service.call

      if service.order
        @order = service.order
        existing_order = Order.find_by!(shopify_id: @order.dig('legacyResourceId'))
        @returns = existing_order.returns

        render(layout: false, content_type: 'application/liquid')
      else
        redirect_to '/a/trial/returns/search?err=not_found', allow_other_hosts: true
      end
    end
  end

  def create
    order = Order.find_by(shopify_id: return_params[:order_id])

    if order.shop_id == @shop.id
      return_order = Return.new(
        shopify_id: return_params[:line_item_id],
        title: return_params[:title],
        shop: @shop,
        order:
      )

      UpdateReturnOrderNoteJob.perform_later(@shop.id, return_order.id) if return_order.save
    end

    redirect_to "/a/trial/returns?name=#{CGI.escape(order.name)}&email=#{CGI.escape(order.email)}"
  end

  def search
    @error = params[:err]
    render(layout: false, content_type: 'application/liquid')
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
      :line_item_id,
      :title
    )
  end
end
