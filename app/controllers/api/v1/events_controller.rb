module Api
  module V1
    class EventsController < ApplicationController
      before_action :set_event, only: [ :show, :update, :destroy, :toggle_featured, :update_status ]

      def index
        events = Event.includes(:branch).order(date_start: :desc)
        events = apply_filters(events)
        events = paginate(events)
        render json: {
          success: true,
          events:  with_booking_counts(events).map { |e| event_json(e) },
          meta:    pagination_meta(events)
        }
      end

      def show
        render json: { success: true, event: event_json(@event) }
      end

      def live
        events = Event.live_now.includes(:branch)
        render json: { success: true, events: with_booking_counts(events).map { |e| event_json(e) } }
      end

      def upcoming
        events = Event.upcoming.includes(:branch)
        if params[:branch_id].present?
          events = events.where("branch_id = ? OR is_global = ?", params[:branch_id], true)
        end
        events = events.limit(30)
        render json: { success: true, events: with_booking_counts(events).map { |e| event_json(e) } }
      end

      def this_week
        events = Event.this_week.includes(:branch)
        if params[:branch_id].present?
          events = events.where("branch_id = ? OR is_global = ?", params[:branch_id], true)
        end
        render json: { success: true, events: with_booking_counts(events).map { |e| event_json(e) } }
      end

      # Weekly line-ups (recurring), optionally for one branch: /events/weekly?branch_id=3
      def weekly
        events = Event.weekly.includes(:branch)
        events = events.where(branch_id: params[:branch_id]) if params[:branch_id].present?
        # Order Monday → Sunday; times after midnight (before 06:00) belong to the end of the night
        night = ->(t) { t.to_s.empty? ? "9" : (t.to_s < "06:00" ? "1#{t}" : "0#{t}") }
        events = events.sort_by { |e| [ e.day_numbers.map { |d| (d + 6) % 7 }.min || 7, night.call(e.time_local), -e.priority.to_i ] }
        render json: { success: true, events: with_booking_counts(events).map { |e| event_json(e) } }
      end

      def featured
        events = Event.featured.one_off.includes(:branch)
        render json: { success: true, events: with_booking_counts(events).map { |e| event_json(e) } }
      end

      def create
        require_admin!
        event = Event.create!(event_params)
        audit(action: "create_event", resource: "Event", resource_id: event.id)
        if event.is_global?
          User.where(role: "member", active: true).find_each do |member|
            Notification.create!(
              user:       member,
              title:      "New Event: #{event.title}",
              body:       "#{event.title} on #{event.date_start}. Book your spot now!",
              notif_type: "event",
              link:       "/whats-on"
            )
          end
        end
        render json: { success: true, event: event_json(event) }, status: :created
      end

      def update
        require_admin!
        @event.update!(event_params)
        audit(action: "update_event", resource: "Event", resource_id: @event.id)
        render json: { success: true, event: event_json(@event) }
      end

      def destroy
        require_admin!
        @event.destroy!
        audit(action: "delete_event", resource: "Event", resource_id: @event.id)
        render json: { success: true, message: "Event deleted" }
      end

      def toggle_featured
        require_admin!
        @event.update!(featured: !@event.featured)
        render json: { success: true, event: event_json(@event) }
      end

      def update_status
        require_admin!
        @event.update!(status: params[:status])
        if params[:status] == "live"
          EventBooking.where(event_id: @event.id, status: "confirmed")
                      .includes(:user)
                      .each do |booking|
            Notification.create!(
              user:       booking.user,
              title:      "#{@event.title} is LIVE now!",
              body:       "Your booked event is starting now at #{booking.branch&.name}.",
              notif_type: "event",
              link:       "/member/bookings"
            )
          end
        end
        render json: { success: true, event: event_json(@event) }
      end

      private

      def set_event
        @event = Event.find(params[:id])
      end

      def event_params
        params.permit(
          :title, :event_type, :league_or_category, :badge, :description,
          :branch_id, :date_start, :date_end, :time_local, :venue_or_city,
          :image_url, :status, :priority, :source, :featured, :is_global,
          :recurrence, :days_of_week, :time_end, :area
        )
      end

      def apply_filters(events)
        events = events.where(event_type: params[:type])              if params[:type].present?
        events = events.where(recurrence: params[:recurrence])        if params[:recurrence].present?
        events = events.where(status: params[:status])                if params[:status].present?
        events = events.where(is_global: true)                        if params[:global] == "true"
        events = events.where("date_start >= ?", params[:from])       if params[:from].present?
        events = events.where("date_start <= ?", params[:to])         if params[:to].present?
        events = events.where("title ILIKE ?", "%#{Event.sanitize_sql_like(params[:search])}%") if params[:search].present?
        if params[:branch_id].present?
          events = events.where(
            "branch_id = ? OR is_global = ?",
            params[:branch_id], true
          )
        end
        events
      end

      # One query for all booking counts in a list (was one query per event)
      def with_booking_counts(events)
        list = events.to_a
        @booking_counts = EventBooking.where(event_id: list.map(&:id)).group(:event_id).count
        list
      end

      def booking_count(event)
        @booking_counts ? @booking_counts.fetch(event.id, 0) : event.event_bookings.count
      end

      def event_json(event)
        {
          id:                 event.id,
          title:              event.title,
          event_type:         event.event_type,
          league_or_category: event.league_or_category,
          badge:              event.badge,
          description:        event.description,
          branch_id:          event.branch_id,
          branch_name:        event.branch&.name,
          branch_slug:        event.branch&.slug,
          date_start:         event.date_start,
          date_end:           event.date_end,
          time_local:         event.time_local,
          venue_or_city:      event.venue_or_city,
          image_url:          event.image_url,
          status:             event.status,
          priority:           event.priority,
          featured:           event.featured,
          is_global:          event.is_global,
          recurrence:         event.recurrence,
          days_of_week:       event.day_numbers,
          time_end:           event.time_end,
          area:               event.area,
          bookings_count:     booking_count(event),
          created_at:         event.created_at
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
