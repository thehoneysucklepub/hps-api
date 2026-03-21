class Event < ApplicationRecord
  belongs_to :branch, optional: true
  has_many :event_bookmarks, dependent: :destroy
  has_many :event_bookings,  dependent: :destroy

  validates :title,      presence: true
  validates :date_start, presence: true
  validates :event_type, inclusion: { in: %w[match promo special] }
  validates :status,     inclusion: { in: %w[scheduled live finished cancelled] }

  scope :upcoming,   -> { where("date_start >= ?", Date.today).order(:date_start) }
  scope :live_now,   -> { where(status: "live") }
  scope :featured,   -> { where(featured: true) }
  scope :global,     -> { where(is_global: true) }
  scope :by_branch,  ->(branch_id) { where(branch_id: branch_id) }
  scope :this_week,  -> { where(date_start: Date.today..Date.today + 7) }
end