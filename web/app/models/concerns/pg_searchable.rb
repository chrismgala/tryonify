module PgSearchable
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model

    pg_search_scope :search_by_name, against: :name, using: { tsearch: { prefix: true } }

    pg_search_scope :address_search,
      associated_against: {
        shipping_address: [:city, :address1, :address2, :zip],
      },
      using: :trigram

    class << self
      def search(query)
        if query.present?
          search_by_name(query)
        else
          order(shopify_created_at: :desc)
        end
      end
    end
  end
end
