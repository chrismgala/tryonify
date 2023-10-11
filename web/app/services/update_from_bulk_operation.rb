# frozen_string_literal: true

class UpdateFromBulkOperation < ApplicationService
  def initialize(bulk_operation)
    super()
    @bulk_operation = bulk_operation
    @current_order = nil
    @returns = []
    @has_selling_plan = false
  end

  def call
    if @bulk_operation.url.present?
      URI.open(@bulk_operation.url) do |f|
        f.each_line {|line| process_line(line) }
      end

      finalize_order if @current_order && @has_selling_plan
    end

    @bulk_operation.destroy if @bulk_operation.status == 'completed'
  rescue StandardError => err
    Rails.logger.error("[#{self.class} Failed]: #{err.message}")
    raise err
  end

  private

  def process_line(line)
    json = JSON.parse(line)
    model = json['id'].split('/')[-2]
  
    case model
    when "Order"
      finalize_order if @current_order && @has_selling_plan
      build_order(json)
    when "LineItem"
      build_line_item(json)
    when "ShippingAddress"
      build_shipping_address(json)
    when "PaymentSchedule"
      get_due_date(json)
    when "OrderTransaction"
      build_transaction(json)
    when "Return"
      build_return(json)
    when "ReturnLineItem"
      build_return_line_item(json)
    end
  end

  def build_order(order_line)
    @current_order = {
      shop_id: @bulk_operation.shop.id,
      shopify_id: order_line['id'],
      name: order_line['name'],
      financial_status: order_line['displayFinancialStatus'],
      email: order_line.dig('customer', 'email'),
      mandate_id: order_line.dig('paymentCollectionDetails', 'vaultedPaymentMethods', 0, 'id'),
      payment_terms_id: order_line.dig('paymentTerms', 'id'),
      shopify_created_at: order_line['createdAt'],
      shopify_updated_at: order_line['updatedAt'],
      fulfillment_status: order_line['displayFulfillmentStatus'],
      closed_at: order_line['closedAt'],
      cancelled_at: order_line['cancelledAt'],
      fully_paid: order_line['fullyPaid'],
      total_outstanding: order_line.dig('totalOutstandingSet', 'shopMoney', 'amount'),
      ip_address: order_line['clientIp'],
      tags: order_line['tags'],
      line_items_attributes: [],
      returns_attributes: [],
      transactions_attributes: order_line['transactions'].map {|transaction| build_transaction(transaction) }
    }
  end

  def build_line_item(line_item)
    selling_plan = SellingPlan.find_by(shopify_id: line_item.dig('sellingPlan', 'sellingPlanId'))
    @has_selling_plan = true if selling_plan
    @current_order[:line_items_attributes] << {
      shopify_id: line_item['id'],
      title: line_item['title'],
      variant_title: line_item['variantTitle'],
      image_url: line_item.dig('image', 'url'),
      quantity: line_item['quantity'],
      unfulfilled_quantity: line_item['unfulfilledQuantity'],
      restockable: line_item['restockable'],
      selling_plan_id: selling_plan&.id
    }
  end

  def build_transaction(transaction)
    transaction_attributes = {
      shopify_id: transaction['id'],
      payment_id: transaction['paymentId'],
      receipt: transaction['receiptJson'],
      kind: transaction['kind'].downcase,
      error: transaction['errorCode'],
      amount: transaction.dig('amountSet', 'shopMoney', 'amount'),
      status: transaction['status'].downcase,
      gateway: transaction['gateway'],
      authorization_expires_at: get_authorization_expiration_date(transaction)
    }

    parent_transaction = Transaction.find_by(shopify_id: transaction.dig('parentTransaction', 'id'))
    if parent_transaction
      parent_transaction.update!(voided: true) if parent_transaction.kind == "authorization" && parent_transaction.voided == false
      transaction_attributes[:parent_transaction] = parent_transaction
    end
    
    transaction_attributes
  end

  def build_return(return_item)
    return if return_item['status'] == 'CANCELED'
    @returns << {
      shop_id: @bulk_operation.shop.id,
      shopify_id: return_item['id'],
      status: return_item['status'].downcase,
      return_line_items_attributes: []
    }
  end

  def build_return_line_item(return_line_item)
    return_item = @returns.find {|x| x[:shopify_id] == return_line_item['__parentId']}

    if return_item
      return_line_item = {
        shopify_id: return_line_item['id'],
        quantity: return_line_item['quantity'],
        shopify_line_item_id: return_line_item.dig('fulfillmentLineItem', 'lineItem', 'id'),
      }
      return_item[:return_line_items_attributes] << return_line_item
    end
  end

  def build_shipping_address(shipping_address)
    @current_order[:shipping_address_attributes] = {
      address1: shipping_address['address1'],
      address2: shipping_address['address2'],
      city: shipping_address['city'],
      zip: shipping_address['zip'],
      province: shipping_address['province'],
      province_code: shipping_address['provinceCode'],
      country: shipping_address['country'],
      country_code: shipping_address['countryCodeV2']
    }
  end

  def get_authorization_expiration_date(transaction)
    if transaction["kind"].downcase == "authorization" && transaction["authorizationExpiresAt"].blank? && transaction["status"].downcase == "success"
      if (transaction["createdAt"].to_datetime + 3.days) < 3.days.from_now
        return transaction["createdAt"].to_datetime + 3.days
      else
        return 3.days.from_now
      end
    end

    transaction["authorizationExpiresAt"]
  end

  def get_due_date(payment_schedule)
    @current_order[:due_date] = payment_schedule['dueAt']
  end

  def finalize_order
    order = Order.includes(:line_items, :returns, :transactions).find_by(shopify_id: @current_order[:shopify_id])

    if order
      associate_return_line_items(order)
      OrderUpdate.call(order_attributes: @current_order, order: order)
    else
      # For new orders, we need to create the order and then create returns
      # so that the returns can be associated with order line items
      order = OrderCreate.call(@current_order)
      associate_return_line_items(order)
      @current_order[:returns_attributes].each do |return_item|
        Return.create!(return_item.merge(order: order))
      end
    end

    @current_order = nil
    @returns = []
    @has_selling_plan = false
  end

  def associate_return_line_items(order)
    @returns.each do |return_item|
      return_item[:return_line_items_attributes].each do |return_line_item|
        line_item = order.line_items.find_by(shopify_id: return_line_item[:shopify_line_item_id])
        return_line_item[:line_item_id] = line_item.id if line_item
        return_line_item.delete(:shopify_line_item_id)
      end
      @current_order[:returns_attributes] << return_item
    end
  end
end