class CreateRecurringCharge
  class InvalidRequest < StandardError; end

  attr_accessor :shopify_domain, :shopify_token

  def initialize(params)
    %w[shopify_domain shopify_token].each do |field|
      raise ArgumentError, "params[:#{field}] is required" if params[field.to_sym].blank?

      # If present, then set as an instance variable
      instance_variable_set("@#{field}", params[field.to_sym])
    end
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def create_charge(plan)
    query = <<~QUERY
      mutation appSubscriptionCreate($lineItems: [AppSubscriptionLineItemInput!]!, $name: String!, $returnUrl: URL!, $trialDays: Int, $test: Boolean) {
        appSubscriptionCreate(lineItems: $lineItems, name: $name, returnUrl: $returnUrl, trialDays: $trialDays, test: $test) {
          appSubscription {
            currentPeriodEnd
            status
            trialDays
          }
          confirmationUrl
          userErrors {
            field
            message
          }
        }
      }
    QUERY

    variables = {
      lineItems: [
        {
          plan: {
            appRecurringPricingDetails: {
              interval: 'EVERY_30_DAYS',
              price: {
                amount: plan.price.to_s,
                currencyCode: 'USD'
              }
            }
          }
        }
      ],
      name: plan.name,
      returnUrl: "https://#{@shopify_domain}/admin/apps/#{ENV.fetch('APP_NAME')}/welcome?shop=#{@shopify_domain}",
      trialDays: plan.trial_days,
      test: ENV.fetch('TEST', '').presence == 'true'
    }

    response = @client.query(query:, variables:)

    unless response.body['errors'].nil?
      raise CreateRecurringCharge::InvalidRequest,
            response.body.dig('errors', 0, 'message') and return
    end

    response.body.dig('data', 'appSubscriptionCreate', 'confirmationUrl')
  rescue StandardError => e
    Rails.logger.error("[CreateRecurringCharge Failed]: #{e.message}")
    @error = e.message
  end
end
