class ReturnsCancelJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)    
    return_item = Return.find_by!(shopify_id: webhook['admin_graphql_api_id'])

    return_item.destroy if return_item
  end
end