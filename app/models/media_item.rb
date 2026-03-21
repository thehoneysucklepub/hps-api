class MediaItem < ApplicationRecord
  belongs_to :branch, optional: true

  validates :file_url,   presence: true
  validates :media_type, inclusion: { in: %w[image video] }

  scope :featured, -> { where(featured: true) }
  scope :ordered,  -> { order(:position) }
end