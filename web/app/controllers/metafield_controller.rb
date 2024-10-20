# frozen_string_literal: true

class MetafieldController < ApplicationController
  def show
    gid_string = "gid://shopify/Metafield/#{params[:shopify_id]}"
    metafield = Metafield.find_by(shopify_id: gid_string)

    render(json: { message: "Metafield not found" }) && return unless metafield

    render(json: {
      data: {
        key: metafield.key,
        value: metafield.value,
      }
    })
  end
end