module Api
  module V1
    class SiteSettingsController < ApplicationController
      before_action :require_admin!

      def index
        settings = SiteSetting.all.order(:group, :key)
        render json: { success: true, settings: settings }
      end

      def show
        setting = SiteSetting.find_by!(key: params[:id])
        render json: { success: true, setting: setting }
      end

      def create
        require_super_admin!
        setting = SiteSetting.create!(setting_params)
        render json: { success: true, setting: setting }, status: :created
      end

      def update
        setting = SiteSetting.find_by!(key: params[:id])
        setting.update!(setting_params)
        audit(action: "update_setting", resource: "SiteSetting", details: params[:id])
        render json: { success: true, setting: setting }
      end

      private

      def setting_params
        params.permit(:key, :value, :group)
      end
    end
  end
end