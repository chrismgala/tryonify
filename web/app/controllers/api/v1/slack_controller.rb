# frozen_string_literal: true

require "rest-client"
require "digest"

class Api::V1::SlackController < ApplicationController
  def index
    if params[:code]
      response = RestClient.post("https://slack.com/api/oauth.v2.access", { "code" => params[:code], "client_id" => ENV.fetch("SLACK_CLIENT_ID", ""),
          "client_secret" => ENV.fetch("SLACK_CLIENT_SECRET"), "redirect_uri" => "#{ENV.fetch("HOST", "").presence}/api/v1/slack", })

      puts response.inspect
      json = JSON.parse(response)
      state = params[:state].split(":")

      shop = Shop.find_by!(shopify_domain: state[0])

      render(json: { message: "Shop not found" }) and return unless shop

      if json["ok"]
        valid_key = Digest::MD5.hexdigest("#{shop.id}#{shop.shopify_domain}")

        if valid_key == state[1]
          shop.slack_token = json["access_token"]
          shop.save!
        end
      end
    end

    redirect_to("https://#{shop.shopify_domain}/admin/apps/#{ENV.fetch("APP_NAME")}/settings",
      allow_other_host: true)
  end
end
