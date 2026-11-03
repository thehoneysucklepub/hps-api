class Event < ApplicationRecord
  belongs_to :branch, optional: true
  has_many :event_bookmarks, dependent: :destroy
  has_many :event_bookings,  dependent: :destroy

  EVENT_TYPES = %w[match promo special lineup].freeze
  RECURRENCES = %w[none weekly].freeze

  validates :title,      presence: true
  validates :date_start, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES }
  validates :status,     inclusion: { in: %w[scheduled live finished cancelled] }
  validates :recurrence, inclusion: { in: RECURRENCES }
  validates :days_of_week, presence: true,
                           format: { with: /\A[0-6](,[0-6])*\z/, message: "must be days 0-6 separated by commas" },
                           if: :weekly?

  before_validation :normalise_days

  scope :one_off,    -> { where(recurrence: "none") }
  scope :weekly,     -> { where(recurrence: "weekly").where.not(status: "cancelled") }
  scope :upcoming,   -> { one_off.where("date_start >= ?", Date.today).order(:date_start) }
  scope :live_now,   -> { where(status: "live") }
  scope :featured,   -> { where(featured: true) }
  scope :global,     -> { where(is_global: true) }
  scope :by_branch,  ->(branch_id) { where(branch_id: branch_id) }
  scope :this_week,  -> { one_off.where(date_start: Date.today..Date.today + 7) }

  def weekly?
    recurrence == "weekly"
  end

  def day_numbers
    days_of_week.to_s.split(",").map(&:to_i)
  end

  private

  # Accept "5, 6" / [5, 6] from the admin and store "5,6"
  def normalise_days
    value = days_of_week
    value = value.join(",") if value.is_a?(Array)
    self.days_of_week = value.to_s.gsub(/\s+/, "").split(",").uniq.sort.join(",").presence
    # Empty form fields are stored as NULL, never ""
    self.area       = area.presence
    self.time_local = time_local.presence
    self.time_end   = time_end.presence
    self.badge      = badge.presence
  end
end
