# frozen_string_literal: true

module Api
  module V1
    class SellingPlanGroupsController < AuthenticatedController
      def index
        service = FetchSellingPlanGroups.new(pagination_params)
        service.call

        render_errors(service.error) and return if service.error

        render(json: service.selling_plan_groups, status: :ok)
      end

      def create
        selling_plan = SellingPlan.new(selling_plan_params[:selling_plan_attributes])
        selling_plan.prepay = selling_plan_params[:prepay] || 0.00
        selling_plan_group = SellingPlanGroup.new(
          name: selling_plan_params[:name],
          description: selling_plan_params[:description],
          shop: current_user,
          selling_plan: selling_plan,
        )

        if selling_plan_group.valid?
          service = CreateSellingPlanGroup.new(selling_plan_group)
          service.call

          if service.selling_plan_group
            selling_plan_group.shopify_id = service.selling_plan_group.dig("id")
            selling_plan_group.selling_plan.shopify_id = service.selling_plan_group.dig("sellingPlans", "edges", 0,
              "node", "id")
            selling_plan_group.save!

            create_selling_plans_metafield_on_shop

            render(json: service.selling_plan_group)
          else
            render_errors(service.error)
          end
        else
          render_errors(selling_plan_group)
        end
      end

      def show
        service = FetchSellingPlanGroup.new(params[:id])
        service.call

        render_errors(service.error) and return if service.error

        render(json: { error: "not found" }, status: :not_found) and return unless service.selling_plan_group

        render(json: service.selling_plan_group)
      end

      def update
        selling_plan_group = SellingPlanGroup.find_by!(shopify_id: params[:id])

        render_errors("Not authorized") and return unless selling_plan_group.shop_id == current_user.id

        selling_plan_group.name = selling_plan_params[:name]
        selling_plan_group.description = selling_plan_params[:description]
        selling_plan_group.selling_plan.name = selling_plan_params[:selling_plan_attributes][:name]
        selling_plan_group.selling_plan.description = selling_plan_params[:selling_plan_attributes][:description]
        selling_plan_group.selling_plan.prepay = selling_plan_params[:selling_plan_attributes][:prepay].presence || 0.00
        selling_plan_group.selling_plan.trial_days = selling_plan_params[:selling_plan_attributes][:trial_days]

        if selling_plan_group.valid?
          service = UpdateSellingPlanGroup.new(selling_plan_group)
          service.call

          render_errors(service.error) and return if service.error

          render_errors(selling_plan_group) and return unless selling_plan_group.save!

          render(json: service.selling_plan_group)
        else
          render_errors(selling_plan_group)
        end
      end

      def destroy
        service = DestroySellingPlanGroup.new(params[:id])
        service.call

        render_errors(service.error) if service.error

        selling_plan_group = SellingPlanGroup.find_by(shopify_id: params[:id])
        selling_plan_group.destroy! if selling_plan_group

        create_selling_plans_metafield_on_shop
      end

      # Get products attached to selling plan group
      def products
        service = FetchSellingPlanGroup.new(params[:id], pagination_params)
        service.call

        render_errors(service.error) and return if service.error

        render(json: service.selling_plan_group["products"])
      end

      private

      def create_selling_plans_metafield_on_shop
        if current_user.selling_plans.any?
          selling_plans = current_user.selling_plans.pluck(:shopify_id)
          attributes = {
            key: "selling_plans",
            namespace: "tryonify",
            ownerId: current_user.shopify_id,
            type: "json_string",
            value: selling_plans.to_json,
          }
          service = CreateMetafield.new
          service.call(attributes)
        end
      end

      def selling_plan_params
        params.permit(
          :id,
          :name,
          :description,
          selling_plan_attributes: [:id, :shopify_id, :name, :description, :prepay, :trial_days]
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
