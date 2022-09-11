class KlaviyoEvent
  def initialize(shop)
    begin
      @shop = shop

      Klaviyo.public_api_key = @shop.klaviyo_public_key
      Klaviyo.private_api_key = @shop.klaviyo_private_key
    rescue StandardError => e
      Rails.logger.error("[Klaviyo Event Failed]: #{e.message}")
    end
  end

  def call(event:, email:, properties:)
    begin
      return if @shop.klaviyo_private_key.blank? || @shop.klaviyo_public_key.blank?

      Klaviyo::Public.track(event,
        method: 'post',
        email: email,
        properties: properties
      )
    rescue StandardError => e
      Rails.logger.error("[Klaviyo Event Failed]: #{e.message}")
    end
  end
end