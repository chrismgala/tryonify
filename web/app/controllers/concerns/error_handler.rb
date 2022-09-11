# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordInvalid do |exception|
      render_errors(exception.record, :unprocessable_entity)
    end
  end

  def render_errors(body, status = :unprocessable_entity)
    json =
      if body.is_a? String
        { message: body }
      else
        { errors: body.errors, message: body.errors.full_messages.join(', ') }
      end

    render json: json, status: status
  end
end
