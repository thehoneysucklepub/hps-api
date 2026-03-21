class MenuItem < ApplicationRecord
  belongs_to :menu_category

  validates :name, presence: true

  scope :available, -> { where(available: true) }
  scope :ordered,   -> { order(:position) }
end