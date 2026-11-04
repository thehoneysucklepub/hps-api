module Api
  module V1
    class SiteSettingsController < ApplicationController
      before_action :require_admin!, except: [ :public_settings ]

      # Groups that are safe to show on the public website.
      # "features" (maintenance_mode, booking_enabled...) stays private.
      PUBLIC_GROUPS = %w[general social contact content barx images].freeze

      # Page photos managed in Admin → Media → Website photos (group "images")
      IMAGE_KEYS = %w[image_home_hero image_branches image_whats_on image_menu].freeze

      def public_settings
        settings = SiteSetting.where(group: PUBLIC_GROUPS)
        render json: { success: true, settings: settings.to_h { |s| [ s.key, s.value ] } }
      end

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
        setting = SiteSetting.find_by(key: params[:id])
        # Website photo slots are created on first save
        setting ||= SiteSetting.new(key: params[:id], group: "images") if IMAGE_KEYS.include?(params[:id])
        raise ActiveRecord::RecordNotFound unless setting

        setting.update!(setting.group == "images" ? { value: params[:value].to_s.strip } : setting_params)
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
