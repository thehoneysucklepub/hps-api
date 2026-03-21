class MenuPdf < ApplicationRecord
  validates :title,    presence: true
  validates :file_url, presence: true
  validates :pdf_type, inclusion: { in: %w[food drinks] }

  scope :active, -> { where(active: true) }
end