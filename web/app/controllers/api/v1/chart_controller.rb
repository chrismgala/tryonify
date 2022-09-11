# frozen_string_literal: true

module Api
  module V1
    class ChartController < AuthenticatedController
      def index
        data = current_user
          .orders
          .where(created_at: (Date.today.at_beginning_of_month - 6.months)..Date.today)
          .group("TO_CHAR(created_at, 'Month YYYY')").count
        render json: data
      end
    end
  end
end