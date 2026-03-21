class MenuCategory < ApplicationRecord
  has_many :menu_items, dependent: :destroy

  validates :name,      presence: true
  validates :menu_type, inclusion: { in: %w[food drinks] }

  scope :active,   -> { where(active: true) }
  scope :ordered,  -> { order(:position) }
end