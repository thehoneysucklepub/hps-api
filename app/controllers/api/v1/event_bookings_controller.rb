module Api
  module V1
    class EventBookingsController < ApplicationController

      def index
        authenticate_user!
        if current_user.can_manage?
          bookings = EventBooking.includes(:user, :event, :branch)
                                 .order(created_at: :desc)
          bookings = bookings.where(branch_id: params[:branch_id]) if params[:branch_id].present?
          bookings = bookings.where(status: params[:status])       if params[:status].present?
          bookings = bookings.where(event_id: params[:event_id])   if params[:event_id].present?
        else
          bookings = current_user.event_bookings
                                 .includes(:event, :branch)
                                 .order(created_at: :desc)
        end
        render json: { success: true, bookings: bookings.map { |b| booking_json(b) } }
      end

      def show
        authenticate_user!
        booking = current_user.can_manage? ?
          EventBooking.find(params[:id]) :
          current_user.event_bookings.find(params[:id])
        render json: { success: true, booking: booking_json(booking) }
      end

      def create
        authenticate_user!
        booking = current_user.event_bookings.create!(
          event_id:  params[:event_id],
          branch_id: params[:branch_id],
          guests:    params[:guests] || 1,
          notes:     params[:notes]
        )
        Notification.create!(
          user:        current_user,
          title:       "Booking Confirmed",
          body:        "Your booking for #{booking.event.title} is confirmed. Code: #{booking.confirmation_code}",
          notif_type:  "success",
          link:        "/member/bookings"
        )
        render json: { success: true, booking: booking_json(booking) }, status: :created
      end

      def update
  authenticate_user!
  raise ExceptionHandler::UnauthorizedError unless current_user.can_manage?
  booking = EventBooking.find(params[:id])
  booking.update!(status: params[:status])
  if params[:status] == "confirmed"
    Notification.create!(
      user:       booking.user,
      title:      "Booking Confirmed!",
      body:       "Your booking for #{booking.event.title} has been confirmed.",
      notif_type: "success"
    )
  end
  render json: { success: true, booking: booking_json(booking) }
end

      def destroy
        authenticate_user!
        booking = current_user.can_manage? ?
          EventBooking.find(params[:id]) :
          current_user.event_bookings.find(params[:id])
        booking.update!(status: "cancelled", cancelled_at: Time.now)
        render json: { success: true, message: "Booking cancelled" }
      end

      private

      def booking_json(b)
        {
          id:                b.id,
          confirmation_code: b.confirmation_code,
          status:            b.status,
          guests:            b.guests,
          notes:             b.notes,
          event_id:          b.event_id,
          event_title:       b.event&.title,
          event_date:        b.event&.date_start,
          event_time:        b.event&.time_local,
          branch_id:         b.branch_id,
          branch_name:       b.branch&.name,
          user_id:           b.user_id,
          username:          b.user&.username,
          confirmed_at:      b.confirmed_at,
          cancelled_at:      b.cancelled_at,
          created_at:        b.created_at
        }
      end
    end
  end
end