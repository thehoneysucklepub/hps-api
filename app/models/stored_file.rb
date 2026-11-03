require "digest"

# A file kept in the database (menu PDFs, venue photos).
# Rows are never changed after upload: a new upload creates a new row,
# so served files can be cached for a long time.
class StoredFile < ApplicationRecord
  PDF_TYPES   = %w[application/pdf].freeze
  IMAGE_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_BYTES   = { "menu_pdf" => 25.megabytes, "photo" => 8.megabytes }.freeze

  has_many :menu_pdfs, dependent: :nullify

  validates :filename, :content_type, :data, presence: true
  validate  :type_and_size

  # Lists never load the file contents
  scope :without_data, -> { select(column_names - [ "data" ]) }

  def self.from_upload(upload, purpose:)
    build_from(upload.read, filename: upload.original_filename, purpose: purpose)
  end

  def self.build_from(bytes, filename:, purpose:)
    bytes = bytes.to_s.b
    new(
      data:         bytes,
      filename:     clean_name(filename, purpose),
      content_type: sniff_type(bytes),
      byte_size:    bytes.bytesize,
      checksum:     Digest::SHA256.hexdigest(bytes),
      purpose:      purpose
    )
  end

  # Decide the type from the file's first bytes, not from its name
  def self.sniff_type(bytes)
    head = bytes.byteslice(0, 12).to_s
    return "application/pdf" if head.start_with?("%PDF")
    return "image/jpeg"      if head.start_with?("\xFF\xD8\xFF".b)
    return "image/png"       if head.start_with?("\x89PNG".b)
    return "image/gif"       if head.start_with?("GIF8")
    return "image/webp"      if head.start_with?("RIFF") && head.byteslice(8, 4) == "WEBP"

    "application/octet-stream"
  end

  def self.clean_name(name, purpose)
    base = File.basename(name.to_s).gsub(/[^\w.\-]+/, "-").gsub(/-+/, "-").delete_prefix("-")
    base = (purpose == "menu_pdf" ? "menu.pdf" : "photo") if base.blank? || base == "."
    base.first(120)
  end

  def pdf?   = PDF_TYPES.include?(content_type)
  def image? = IMAGE_TYPES.include?(content_type)

  # Public path under /api/v1, e.g. "files/12/osu.jpg"
  def path = "files/#{id}/#{filename}"

  def as_json(*)
    { id: id, filename: filename, content_type: content_type, byte_size: byte_size, purpose: purpose, created_at: created_at }
  end

  private

  def type_and_size
    allowed = purpose == "menu_pdf" ? PDF_TYPES : (PDF_TYPES + IMAGE_TYPES)
    allowed = IMAGE_TYPES if purpose == "photo"
    unless allowed.include?(content_type)
      errors.add(:base, purpose == "menu_pdf" ? "File is not a PDF" : "File must be a JPG, PNG, WebP or GIF image")
    end

    limit = MAX_BYTES.fetch(purpose.to_s, 25.megabytes)
    errors.add(:base, "File is too large (max #{limit / 1.megabyte} MB)") if byte_size.to_i > limit
  end
end
