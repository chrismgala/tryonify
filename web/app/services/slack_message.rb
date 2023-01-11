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
    conversations = @client.conversations_list.channels
    channel = conversations.detect(&:is_member)
    @client.chat_postMessage(text: message, channel: channel.id, as_user: true)
  rescue StandardError => e
    Rails.logger.error("[Slack Message Failed]: #{e.message}")
  end
end
