module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_notification, only: [:show, :destroy, :mark_read]

      def index
        notifs = current_user.notifications.recent
        json_success(
          notifications: notifs,
          unread_count: current_user.notifications.unread.count
        )
      end

      def show
        json_success(notification: @notification)
      end

      def destroy
        @notification.destroy!
        json_success(message: "Notification deleted")
      end

      def mark_read
        @notification.update!(read: true)
        json_success(notification: @notification)
      end

      def mark_all_read
        current_user.notifications.unread.update_all(read: true)
        json_success(message: "All notifications marked as read")
      end

      private

      def set_notification
        @notification = current_user.notifications.find(params[:id])
      end
    end
  end
end