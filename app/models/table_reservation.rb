class TableReservation < ApplicationRecord
  belongs_to :user
  belongs_to :branch

  validates :date,              presence: true
  validates :time,              presence: true
  validates :guests,            presence: true, numericality: { greater_than: 0 }
  validates :confirmation_code, presence: true, uniqueness: true
  validates :status,            inclusion: { in: %w[pending confirmed cancelled completed] }

  before_validation :generate_confirmation_code, on: :create

  scope :pending,   -> { where(status: "pending") }
  scope :confirmed, -> { where(status: "confirmed") }
  scope :upcoming,  -> { where("date >= ?", Date.today).order(:date, :time) }

  private

  def generate_confirmation_code
    self.confirmation_code ||= "TBL-#{SecureRandom.hex(4).upcase}"
  end
end