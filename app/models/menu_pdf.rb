class MenuPdf < ApplicationRecord
  TYPES = %w[food drinks].freeze

  belongs_to :stored_file, optional: true

  validates :title,    presence: true
  validates :pdf_type, inclusion: { in: TYPES }
  validate  :link_or_file

  scope :active,  -> { where(active: true) }
  scope :ordered, -> { order(:position, Arel.sql("CASE pdf_type WHEN 'food' THEN 0 ELSE 1 END"), :id) }

  before_validation { self.file_url = file_url.to_s.strip.presence }
  after_save :remove_replaced_file


  def stored? = stored_file_id.present?

  # Copy the PDF at file_url into the database. Returns the StoredFile.
  def store_from_link!
    bytes = RemotePdf.fetch(file_url)
    attach_bytes!(bytes, filename: "#{title.parameterize.presence || 'menu'}.pdf")
  end

  def attach_bytes!(bytes, filename:)
    file = StoredFile.build_from(bytes, filename: filename, purpose: "menu_pdf")
    transaction do
      file.save!
      update!(stored_file: file)
    end
    file
  end

  # base: public API address ending in /api/v1
  def as_api_json(base)
    file = stored? ? StoredFile.without_data.find_by(id: stored_file_id) : nil
    {
      id:          id,
      title:       title,
      pdf_type:    pdf_type,
      active:      active,
      position:    position,
      file_url:    file_url,          # the original link (e.g. Google Drive)
      preview_url: file_url.present? ? RemotePdf.preview_url(file_url) : nil,
      stored:      file.present?,
      file: file && {
        filename:   file.filename,
        byte_size:  file.byte_size,
        updated_at: file.created_at,
        view_url:     "#{base}/menu_pdfs/#{id}/file?v=#{file.id}",
        download_url: "#{base}/menu_pdfs/#{id}/file?download=1&v=#{file.id}"
      },
      # Always works: the stored copy if there is one, else the link
      download_url: "#{base}/menu_pdfs/#{id}/file?download=1#{file ? "&v=#{file.id}" : ''}",
      updated_at:  updated_at
    }
  end

  private

  # A replaced PDF is deleted once no menu uses it
  def remove_replaced_file
    old_id = saved_change_to_stored_file_id&.first
    return unless old_id

    StoredFile.where(id: old_id).where.not(id: MenuPdf.where.not(stored_file_id: nil).select(:stored_file_id)).delete_all
  end

  def link_or_file
    errors.add(:base, "Add a PDF link or upload a PDF file") if file_url.blank? && stored_file_id.blank?
  end
end
