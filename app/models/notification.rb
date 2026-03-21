class Notification < ApplicationRecord
  belongs_to :user

  validates :title,       presence: true
  validates :notif_type,  inclusion: { in: %w[info success warning event] }

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc).limit(20) }
end