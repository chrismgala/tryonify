class Shopify::Base < ApplicationService
  private

  def shop
    unless @shop
      @shop = Shop.find_by(shopify_domain: session.shop)
    end
    @shop
  end

  def session
    unless @session
      @session = ShopifyAPI::Context.active_session
    end
    @session
  end

  def client
    unless @client
      @client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
    end
    @client
  end
end