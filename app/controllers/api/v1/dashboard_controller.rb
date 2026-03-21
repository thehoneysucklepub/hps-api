module Api
  module V1
    class DashboardController < ApplicationController
      before_action :require_staff_or_admin!

      def stats
        render json: { success: true, stats: {
          events: {
            total:     Event.count,
            scheduled: Event.where(status: "scheduled").count,
            live:      Event.where(status: "live").count,
            this_week: Event.this_week.count,
            featured:  Event.featured.count
          },
          users: {
            total:   User.count,
            admins:  User.admins.count,
            members: User.where(role: "member").count,
            staff:   User.where(role: "staff").count
          },
          branches: {
            total:  Branch.count,
            active: Branch.active.count
          },
          media: {
            total: MediaItem.count
          },
          bookings: {
            total:     EventBooking.count,
            pending:   EventBooking.where(status: "pending").count,
            confirmed: EventBooking.where(status: "confirmed").count
          },
          reservations: {
            total:     TableReservation.count,
            pending:   TableReservation.where(status: "pending").count,
            confirmed: TableReservation.where(status: "confirmed").count,
            today:     TableReservation.where(date: Date.today).count
          },
          recent_activity: AuditLog.recent.limit(10).map do |log|
            {
              id:          log.id,
              action:      log.action,
              resource:    log.resource,
              resource_id: log.resource_id,
              user:        log.user&.username,
              created_at:  log.created_at
            }
          end
        }}
      end
    end
  end
end