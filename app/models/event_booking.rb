class EventBooking < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :branch

  validates :guests,            presence: true, numericality: { greater_than: 0 }
  validates :confirmation_code, presence: true, uniqueness: true
  validates :status,            inclusion: { in: %w[pending confirmed cancelled attended] }

  before_validation :generate_confirmation_code, on: :create

  scope :pending,   -> { where(status: "pending") }
  scope :confirmed, -> { where(status: "confirmed") }
  scope :upcoming,  -> { joins(:event).where("events.date_start >= ?", Date.today) }

  private

  def generate_confirmation_code
    self.confirmation_code ||= "HPS-#{SecureRandom.hex(4).upcase}"
  end
end