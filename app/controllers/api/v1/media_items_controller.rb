module Api
  module V1
    class MediaItemsController < ApplicationController
      before_action :set_item, only: [:show, :update, :destroy, :toggle_featured]

      def index
        items = MediaItem.includes(:branch).ordered
        items = items.where(media_type: params[:media_type]) if params[:media_type].present?
        items = items.where(branch_id: params[:branch_id])   if params[:branch_id].present?
        items = items.where(featured: true)                  if params[:featured] == "true"

        if params[:grouped] == "true"
          grouped = items.group_by { |i| i.branch&.name || "Global" }
          render json: {
            success: true,
            grouped: grouped.map { |branch_name, media|
              { branch: branch_name, items: media.map { |i| media_json(i) } }
            },
            media_items: items.map { |i| media_json(i) }
          }
        else
          render json: { success: true, media_items: items.map { |i| media_json(i) } }
        end
      end

      def show
        render json: { success: true, media_item: media_json(@item) }
      end

      def create
        require_admin!
        item = MediaItem.create!(media_params)
        render json: { success: true, media_item: media_json(item) }, status: :created
      end

      def update
        require_admin!
        @item.update!(media_params)
        render json: { success: true, media_item: media_json(@item) }
      end

      def destroy
        require_admin!
        @item.destroy!
        render json: { success: true, message: "Media deleted" }
      end

      def toggle_featured
        require_admin!
        @item.update!(featured: !@item.featured)
        render json: { success: true, media_item: media_json(@item) }
      end

      private

      def set_item
        @item = MediaItem.find(params[:id])
      end

      def media_params
        params.permit(:title, :media_type, :file_url, :thumbnail_url,
                      :branch_id, :featured, :position)
      end

      def media_json(item)
        {
          id:            item.id,
          title:         item.title,
          media_type:    item.media_type,
          file_url:      item.file_url,
          thumbnail_url: item.thumbnail_url,
          branch_id:     item.branch_id,
          branch_name:   item.branch&.name,
          featured:      item.featured,
          position:      item.position,
          created_at:    item.created_at
        }
      end
    end
  end
end