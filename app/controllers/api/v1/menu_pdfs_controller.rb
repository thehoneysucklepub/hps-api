module Api
  module V1
    class MenuPdfsController < ApplicationController
      before_action :set_pdf, only: [:show, :update, :destroy]

      def index
        pdfs = MenuPdf.active.order(:pdf_type)
        render json: { success: true, menu_pdfs: pdfs }
      end

      def show
        render json: { success: true, menu_pdf: @pdf }
      end

      def create
        require_admin!
        pdf = MenuPdf.create!(pdf_params)
        render json: { success: true, menu_pdf: pdf }, status: :created
      end

      def update
        require_admin!
        @pdf.update!(pdf_params)
        render json: { success: true, menu_pdf: @pdf }
      end

      def destroy
        require_admin!
        @pdf.destroy!
        render json: { success: true, message: "PDF deleted" }
      end

      private

      def set_pdf
        @pdf = MenuPdf.find(params[:id])
      end

      def pdf_params
        params.permit(:title, :file_url, :pdf_type, :active)
      end
    end
  end
end