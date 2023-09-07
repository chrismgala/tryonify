# frozen_string_literal: true

class ValidateOrder < ApplicationService
  def initialize(order)
    super()
    @order = order
    @errors = []
  end

  def call
    validate

    unless @errors.length.zero?
      if @order.shop.slack_token
        
        message = "*Invalid Order #{@order.name}*\n\n"

        @errors.each do |error|
          message += "- #{error}\n"
        end

        SlackMessageJob.perform_later(@order.shop.id, message)
      end
    end

    @errors
  end

  private

  def validate
    # Customer already has an active trial
    has_same_email?
    has_similar_address?
    has_same_ip_address?

    # Customer has invalid payment method
    has_prepaid_card?
  end

  def has_prepaid_card?
    @order.transactions.any? { |transaction| transaction.prepaid_card? }
  end

  def has_same_email?
    # Pending order exists for same email and shop
    regex = '(\+.*?(?=@))|\.'
    orders = Order.where(shop: @order.shop)
      .where("regexp_replace(email, ?, '', 'g') = ?", regex, @order.email.gsub('.', ''))
      .pending
      .where.not(id: @order.id)

    if orders.length.positive?
      @errors << "Pending orders with same e-mail: #{orders.map(&:name).join(", ")}"
    end
  end

  def has_same_ip_address?
    orders = Order.where(shop: @order.shop, ip_address: @order.ip_address)
      .pending
      .where.not(id: @order.id)

    if orders.length.positive?
      @errors << "Pending orders with same IP address: #{orders.map(&:name).join(", ")}"
    end
  end

  def has_similar_address?
    shipping_address = @order.shipping_address

    return unless shipping_address

    orders = Order.where(shop: @order.shop)
      .pending
      .where.not(id: @order.id)
      .address_search("#{shipping_address.city} #{shipping_address.address1} #{shipping_address.address2} #{shipping_address.zip}")

    if orders.length.positive?
      @errors << "Pending orders with similar address: #{orders.map(&:name).join(", ")}"
    end
  end
end
