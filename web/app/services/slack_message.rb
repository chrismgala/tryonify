# frozen_string_literal: true

class SlackMessage
  attr_accessor :error

  def initialize(shop)
    @shop = shop
    @error = nil

    @error = "No Slack token" and return if @shop.slack_token.blank?

    @client = Slack::Web::Client.new(token: @shop.slack_token)
  end

  def send(message)
    raise "No Slack channel" and return if @shop.slack_channel.blank?

    @client.chat_postMessage(channel: @shop.slack_channel, text: message, as_user: true)
  rescue StandardError => e
    Rails.logger.error("[Slack Message Failed]: #{e.message}")
  end
end
