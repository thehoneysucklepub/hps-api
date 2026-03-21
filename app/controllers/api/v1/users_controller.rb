module Api
  module V1
    class UsersController < ApplicationController
      before_action :require_admin!
      before_action :set_user, only: [:show, :update, :destroy, :toggle_active, :notifications]

      def index
        users = User.includes(:branch).order(:created_at)
        users = users.where(role: params[:role]) if params[:role].present?
        users = users.where(branch_id: params[:branch_id]) if params[:branch_id].present?
        users = paginate(users)
        render json: {
          success: true,
          users: users.map { |u| user_json(u) },
          meta: pagination_meta(users)
        }
      end

      def show
        render json: { success: true, user: user_json(@user) }
      end

      def create
        raise ExceptionHandler::UnauthorizedError unless current_user.super_admin? || params[:role] != "super_admin"
        user = User.new(user_params)
        user.save!
        audit(action: "create_user", resource: "User", resource_id: user.id)
        render json: { success: true, user: user_json(user) }, status: :created
      end

      def update
        raise ExceptionHandler::UnauthorizedError if @user.super_admin? && !current_user.super_admin?
        @user.update!(user_params)
        audit(action: "update_user", resource: "User", resource_id: @user.id)
        render json: { success: true, user: user_json(@user) }
      end

      def destroy
        raise ExceptionHandler::UnauthorizedError if @user.super_admin?
        raise ExceptionHandler::UnauthorizedError if @user == current_user
        @user.destroy!
        audit(action: "delete_user", resource: "User", resource_id: @user.id)
        render json: { success: true, message: "User deleted" }
      end

      def toggle_active
        raise ExceptionHandler::UnauthorizedError if @user.super_admin?
        @user.update!(active: !@user.active)
        render json: { success: true, user: user_json(@user) }
      end

      def notifications
        notifs = @user.notifications.recent
        render json: { success: true, notifications: notifs }
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        allowed = [:username, :email, :password, :first_name, :last_name, :phone, :avatar_url, :branch_id]
        allowed << :role if current_user.super_admin?
        params.permit(*allowed)
      end

      def user_json(user)
        {
          id:            user.id,
          username:      user.username,
          email:         user.email,
          role:          user.role,
          full_name:     user.full_name,
          first_name:    user.first_name,
          last_name:     user.last_name,
          phone:         user.phone,
          avatar_url:    user.avatar_url,
          branch_id:     user.branch_id,
          branch_name:   user.branch&.name,
          active:        user.active,
          last_login_at: user.last_login_at,
          created_at:    user.created_at
        }
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages:  collection.total_pages,
          total_count:  collection.total_count,
          per_page:     collection.limit_value
        }
      end
    end
  end
end