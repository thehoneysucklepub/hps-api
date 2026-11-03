module Api
  module V1
    # Photos and PDFs stored in the database.
    #   POST /files            (admin, multipart "file", optional "purpose": photo|menu_pdf)
    #   GET  /files/:id/:name  (public) → the file
    class FilesController < ApplicationController
      include PublicUrls

      before_action :require_admin!, only: [ :create, :index, :destroy ]

      def index
        files = StoredFile.without_data.order(created_at: :desc).limit(200)
        files = files.where(purpose: params[:purpose]) if params[:purpose].present?
        render json: { success: true, files: files.map { |f| f.as_json.merge(url: "#{api_base_url}/#{f.path}") } }
      end

      def create
        upload = params[:file]
        unless upload.respond_to?(:read)
          return render json: { success: false, error: "Choose a file to upload" }, status: :unprocessable_entity
        end

        purpose = params[:purpose].presence_in(%w[photo menu_pdf]) || "photo"
        file = StoredFile.from_upload(upload, purpose: purpose)
        file.save!
        audit(action: "upload_file", resource: "StoredFile", resource_id: file.id)
        render json: { success: true, file: file.as_json, url: "#{api_base_url}/#{file.path}" }, status: :created
      end

      def show
        file = StoredFile.find(params[:id])
        send_stored(file, download: params[:download].present?)
      end

      def destroy
        file = StoredFile.without_data.find(params[:id])
        file.destroy!
        render json: { success: true }
      end
    end
  end
end
