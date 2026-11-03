class Branch < ApplicationRecord
  has_many :users
  has_many :events
  has_many :media_items

  VENUE_TYPES = %w[pub bar restaurant].freeze

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  validates :venue_type, inclusion: { in: VENUE_TYPES }

  scope :active,  -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  # Optional page sections (Admin → Branches → Page sections)
  SECTION_FIELDS = {
    "stats"      => %w[value label],
    "features"   => %w[title text],
    "signatures" => %w[name text price]
  }.freeze

  before_validation :generate_slug, on: :create
  before_validation :clean_sections

  private

  # Keep only known keys, trim text, drop empty rows
  def clean_sections
    SECTION_FIELDS.each do |field, keys|
      rows = Array(self[field]).filter_map do |row|
        row = row.to_h.stringify_keys.slice(*keys).transform_values { |v| v.to_s.strip }
        row if row.values.any?(&:present?)
      end
      self[field] = rows.first(24)
    end
    %i[eyebrow story_title story signatures_title tagline image_url map_url].each do |f|
      self[f] = self[f].to_s.strip.presence
    end
  end

  def generate_slug
    self.slug ||= name.to_s.downcase.gsub(/\s+/, "-").gsub(/[^a-z0-9-]/, "")
  end
end
