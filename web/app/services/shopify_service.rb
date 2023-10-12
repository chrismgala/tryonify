class ShopifyService < ApplicationService
  def client
    unless @client
      @session = ShopifyAPI::Context.active_session
      @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
    end
    @client
  end
end