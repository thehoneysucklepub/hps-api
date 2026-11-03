module Api
  module V1
    # Menu PDFs. Each menu has a link (e.g. Google Drive) and/or a copy stored
    # in the database, which the website shows in its PDF reader and offers
    # for download from GET /menu_pdfs/:id/file.
    class MenuPdfsController < ApplicationController
      include PublicUrls

      before_action :set_pdf, only: [ :show, :update, :destroy, :file, :fetch, :upload ]
      before_action :require_admin!, only: [ :create, :update, :destroy, :fetch, :upload ]

      def index
        pdfs = params[:all] == "true" && admin_request? ? MenuPdf.all : MenuPdf.active
        render json: { success: true, menu_pdfs: pdfs.ordered.map { |p| p.as_api_json(api_base_url) } }
      end

      def show
        render json: { success: true, menu_pdf: @pdf.as_api_json(api_base_url) }
      end

      # Accepts JSON or multipart (with an optional "file" PDF)
      def create
        pdf = MenuPdf.new(pdf_params)
        MenuPdf.transaction do
          attach_upload(pdf) if params[:file].present?
          pdf.save!
        end
        store_link_copy(pdf) if params[:file].blank? && params[:store_copy].to_s == "true"
        audit(action: "create_menu_pdf", resource: "MenuPdf", resource_id: pdf.id)
        render json: { success: true, menu_pdf: pdf.reload.as_api_json(api_base_url), warning: @warning }.compact, status: :created
      end

      def update
        MenuPdf.transaction do
          @pdf.assign_attributes(pdf_params)
          attach_upload(@pdf) if params[:file].present?
          @pdf.save!
        end
        audit(action: "update_menu_pdf", resource: "MenuPdf", resource_id: @pdf.id)
        render json: { success: true, menu_pdf: @pdf.reload.as_api_json(api_base_url) }
      end

      def destroy
        file = @pdf.stored_file
        @pdf.destroy!
        file&.destroy! if file && file.menu_pdfs.none?
        audit(action: "delete_menu_pdf", resource: "MenuPdf", resource_id: @pdf.id)
        render json: { success: true, message: "PDF deleted" }
      end

      # POST /menu_pdfs/:id/upload  (multipart "file") — replace the stored PDF
      def upload
        return render(json: { success: false, error: "Choose a PDF file" }, status: :unprocessable_entity) if params[:file].blank?

        MenuPdf.transaction { attach_upload(@pdf); @pdf.save! }
        audit(action: "upload_menu_pdf", resource: "MenuPdf", resource_id: @pdf.id)
        render json: { success: true, menu_pdf: @pdf.reload.as_api_json(api_base_url) }
      end

      # POST /menu_pdfs/:id/fetch — copy the PDF from its link into the database
      def fetch
        @pdf.store_from_link!
        audit(action: "fetch_menu_pdf", resource: "MenuPdf", resource_id: @pdf.id)
        render json: { success: true, menu_pdf: @pdf.reload.as_api_json(api_base_url) }
      rescue RemotePdf::Error => e
        render json: { success: false, error: e.message }, status: :unprocessable_entity
      end

      # GET /menu_pdfs/:id/file            → show the PDF (inline)
      # GET /menu_pdfs/:id/file?download=1 → download it
      # Without a stored copy, sends the visitor to the link instead.
      def file
        download = params[:download].present?
        if @pdf.stored?
          stored = @pdf.stored_file
          send_stored(stored, download: download, filename: download_name(stored),
                              immutable: params[:v].to_s == stored.id.to_s)
        elsif @pdf.file_url.present?
          redirect_to(download ? RemotePdf.download_url(@pdf.file_url) : RemotePdf.preview_url(@pdf.file_url), allow_other_host: true)
        else
          render json: { success: false, error: "No file for this menu" }, status: :not_found
        end
      end

      private

      def set_pdf
        @pdf = MenuPdf.find(params[:id])
      end

      def pdf_params
        params.permit(:title, :file_url, :pdf_type, :active, :position)
      end

      def attach_upload(pdf)
        file = StoredFile.from_upload(params[:file], purpose: "menu_pdf")
        raise ActiveRecord::RecordInvalid, file unless file.valid?

        file.save!
        pdf.stored_file = file
      end

      def store_link_copy(pdf)
        pdf.store_from_link!
      rescue RemotePdf::Error => e
        @warning = "Saved, but the PDF could not be copied from the link: #{e.message}"
      end

      def download_name(stored)
        "honeysuckle-#{@pdf.title.parameterize.presence || 'menu'}.pdf".presence || stored.filename
      end
    end
  end
end
