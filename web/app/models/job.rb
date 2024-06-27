class Job < ApplicationRecord
  validates :shopify_id, presence: true, uniqueness: true

  belongs_to :shop, dependent: :destroy
  belongs_to :jobable, polymorphic: true

  def done?
    done_at.present?
  end

  def status
    raise NotImplementedError
  end
end
