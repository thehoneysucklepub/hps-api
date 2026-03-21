module Api
  module V1
    class EventBookmarksController < ApplicationController
      before_action :authenticate_user!

      def index
        bookmarks = current_user.event_bookmarks.includes(:event)
        render json: {
          success: true,
          bookmarks: bookmarks.map { |b|
            {
              id:         b.id,
              event_id:   b.event_id,
              event:      b.event,
              created_at: b.created_at
            }
          }
        }
      end

      def create
        bookmark = current_user.event_bookmarks.find_or_create_by!(
          event_id: params[:event_id]
        )
        render json: { success: true, bookmark: bookmark }, status: :created
      end

      def destroy
        bookmark = current_user.event_bookmarks.find(params[:id])
        bookmark.destroy!
        render json: { success: true, message: "Bookmark removed" }
      end
    end
  end
end