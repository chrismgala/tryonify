# frozen_string_literal: true

module Api
  module V1
    class SellingPlanGroupsController < AuthenticatedController
      def index
        service = FetchSellingPlanGroups.new(pagination_params)
        service.call

        render_errors service.error and return if service.error
        render json: service.selling_plan_groups, status: :ok
      end

      def create
        selling_plan_group = SellingPlanGroup.new(
          name: selling_plan_params[:name],
          description: selling_plan_params[:description],
          shop: current_user,
          selling_plan: SellingPlan.new(selling_plan_params[:selling_plan])
        )

        if selling_plan_group.valid?
          service = CreateSellingPlanGroup.new(selling_plan_group)
          service.call

          if service.selling_plan_group
            render json: service.selling_plan_group
          else
            render_errors service.error
          end
        else
          render_errors selling_plan_group
        end
      end

      def show
        service = FetchSellingPlanGroup.new(params[:id])
        service.call

        render_errors service.error and return if service.error
        render json: service.selling_plan_group
      end

      def update
        selling_plan_group = SellingPlanGroup.new(
          shopify_id: selling_plan_params[:id],
          name: selling_plan_params[:name],
          description: selling_plan_params[:description],
          shop: current_user,
          selling_plan: SellingPlan.new(selling_plan_params[:selling_plan])
        )

        if selling_plan_group.valid?
          service = UpdateSellingPlanGroup.new(selling_plan_group)
          service.call

          if service.selling_plan_group
            render json: service.selling_plan_group
          else
            render_errors service.error
          end
        else
          render_errors selling_plan_group
        end
      end

      def destroy
        service = DestroySellingPlanGroup.new(params[:id])
        response = service.call

        render_errors service.error if service.error
      end

      # Get products attached to selling plan group
      def products
        service = FetchSellingPlanGroup.new(params[:id], pagination_params)
        service.call

        render_errors service.error and return if service.error
        render json: service.selling_plan_group['products']
      end

      private

      def selling_plan_params
        params.permit(
          :id,
          :name,
          :description,
          selling_plan: [
            :shopify_id,
            :name,
            :description,
            :prepay,
            :trial_days
          ]
        )
      end

      def pagination_params
        params.permit(
          :first,
          :last,
          :before,
          :after
        )
      end
    end
  end
end
