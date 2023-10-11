# frozen_string_literal: true

class Shopify::PaymentTerms::Update < Shopify::Base
  PAYMENT_TERMS_UPDATE_QUERY = <<~QUERY
    mutation paymentTermsUpdate($input: PaymentTermsUpdateInput!) {
      paymentTermsUpdate(input: $input) {
        paymentTerms {
          id
          paymentSchedules(first: 1) {
            edges {
              node {
                dueAt
              }
            }
          }
        }
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  def initialize(payment_terms_id:, due_date:)
    @payment_terms_id = payment_terms_id
    @due_date = due_date
  end

  def call
    query = PAYMENT_TERMS_UPDATE_QUERY
    variables = {
      input: {
        paymentTermsId: @payment_terms_id,
        paymentTermsAttributes: {
          paymentSchedules: [{
            dueAt: @due_date
          }]
        }
      }
    }
    response = client.query(query:, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    unless response.body.dig("data", "paymentTermsUpdate", "userErrors").empty?
      raise response.body.dig("data", "paymentTermsUpdate", "userErrors", 0, "message") and return
    end

    response
  rescue => err
    Rails.logger.error("[#{self.class} Failed]: #{err.message}")
    raise err
  end
end