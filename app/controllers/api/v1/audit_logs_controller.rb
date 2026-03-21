module Api
  module V1
    class AuditLogsController < ApplicationController
      before_action :require_super_admin!

      def index
        logs = AuditLog.includes(:user).recent
        logs = logs.where(user_id:  params[:user_id])    if params[:user_id].present?
        logs = logs.where(action:   params[:log_action]) if params[:log_action].present?
        logs = logs.where(resource: params[:resource])   if params[:resource].present?
        logs = paginate(logs)

        render json: {
          success: true,
          logs: logs.map { |l|
            {
              id:          l.id,
              action:      l.action,
              resource:    l.resource,
              resource_id: l.resource_id,
              details:     l.details,
              ip_address:  l.ip_address,
              user:        l.user&.username,
              created_at:  l.created_at
            }
          },
          meta: {
            current_page: logs.current_page,
            total_pages:  logs.total_pages,
            total_count:  logs.total_count
          }
        }
      end
    end
  end
end