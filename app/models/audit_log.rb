class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def self.record(user:, action:, resource: nil, resource_id: nil, details: nil, ip: nil)
    create(
      user: user,
      action: action,
      resource: resource,
      resource_id: resource_id,
      details: details,
      ip_address: ip
    )
  end
end