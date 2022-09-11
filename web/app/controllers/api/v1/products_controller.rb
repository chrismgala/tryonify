# frozen_string_literal: true

module Api
  module V1
    class ProductsController < AuthenticatedController
      def index
        service = FetchProducts.new(pagination_params)
        service.call
    
        render_errors service.error and return if service.error
        render json: service.products
      end

      # def create
      #   selling_plan_group = SellingPlanGroup.find(params[:id])
        
      #   service = UpdateSellingPlanProducts.new(selling_plan_group.shopify_id, params[:product_ids])
      #   service.call

      #   render_errors service.error and return if service.error

      #   products = params[:product_ids].each do |id|
      #     {
      #       shopify_id: id,
      #       shop: current_user,
      #       selling_plan_group: selling_plan_group
      #     }
      #   end

      #   result = Product.insert_all!(products)
      # end
    
      def products_params
        params.permit(
          product_ids: []
        )
      end

      def pagination_params
        params.permit(
          :query,
          :before,
          :after,
          :first,
          :last
        )
      end
    end
  end
end