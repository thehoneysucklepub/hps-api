class Branch < ApplicationRecord
  has_many :users
  has_many :events
  has_many :media_items

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true) }

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug ||= name.to_s.downcase.gsub(/\s+/, "-").gsub(/[^a-z0-9-]/, "")
  end
end