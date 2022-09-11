# frozen_string_literal: true

module Api
  module V1
    class SellingPlanProductsController < AuthenticatedController
      def index
        service = FetchSellingPlanGroup.new(
          params[:selling_plan_group_id],
          pagination_params
        )
        service.call

        render_errors service.error and return if service.error
        render json: service.selling_plan_group.dig('products')
      end

      def create
        # Add products to selling plan group
        if (product_params[:add_products] && product_params[:add_products].length > 0)
          service = UpdateSellingPlanProducts.new(params[:selling_plan_group_id], product_params[:add_products])
          service.call

          render_errors service.error and return if service.error
        end

        # Remove products from selling plan group
        if (product_params[:remove_products] && product_params[:remove_products].length > 0)
          removeService = RemoveSellingPlanProducts.new(params[:selling_plan_group_id], product_params[:remove_products])
          removeService.call

          render_errors removeService.error and return if removeService.error
        end

        render json: {}
      end

      private

      def product_params
        params.require(:selling_plan_product).permit(
          add_products: [],
          remove_products: []
        )
      end

      def pagination_params
        params.permit(
          :before,
          :after,
          :first,
          :last
        )
      end
    end
  end
end