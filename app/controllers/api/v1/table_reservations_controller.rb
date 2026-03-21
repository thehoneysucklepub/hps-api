module Api
  module V1
    class TableReservationsController < ApplicationController

      def index
        authenticate_user!
        if current_user.can_manage?
          reservations = TableReservation.includes(:user, :branch)
                                         .order(date: :asc, time: :asc)
          reservations = reservations.where(branch_id: params[:branch_id]) if params[:branch_id].present?
          reservations = reservations.where(status: params[:status])       if params[:status].present?
          reservations = reservations.where(date: params[:date])           if params[:date].present?
        else
          reservations = current_user.table_reservations
                                     .includes(:branch)
                                     .order(date: :asc)
        end
        render json: { success: true, reservations: reservations.map { |r| reservation_json(r) } }
      end

      def show
        authenticate_user!
        reservation = current_user.can_manage? ?
          TableReservation.find(params[:id]) :
          current_user.table_reservations.find(params[:id])
        render json: { success: true, reservation: reservation_json(reservation) }
      end

      def create
        authenticate_user!
        reservation = current_user.table_reservations.create!(
          branch_id: params[:branch_id],
          date:      params[:date],
          time:      params[:time],
          guests:    params[:guests] || 2,
          occasion:  params[:occasion],
          notes:     params[:notes]
        )
        Notification.create!(
          user:       current_user,
          title:      "Reservation Received",
          body:       "Table reservation at #{reservation.branch.name} on #{reservation.date}. Code: #{reservation.confirmation_code}",
          notif_type: "info",
          link:       "/member/reservations"
        )
        render json: { success: true, reservation: reservation_json(reservation) }, status: :created
      end

     def update
  authenticate_user!
  raise ExceptionHandler::UnauthorizedError unless current_user.can_manage?
  reservation = TableReservation.find(params[:id])
  reservation.update!(status: params[:status])
  if params[:status] == "confirmed"
    Notification.create!(
      user:       reservation.user,
      title:      "Reservation Confirmed!",
      body:       "Your table at #{reservation.branch.name} on #{reservation.date} is confirmed.",
      notif_type: "success"
    )
  end
  render json: { success: true, reservation: reservation_json(reservation) }
end

      def destroy
        authenticate_user!
        reservation = current_user.can_manage? ?
          TableReservation.find(params[:id]) :
          current_user.table_reservations.find(params[:id])
        reservation.update!(status: "cancelled", cancelled_at: Time.now)
        render json: { success: true, message: "Reservation cancelled" }
      end

      private

      def reservation_json(r)
        {
          id:                r.id,
          confirmation_code: r.confirmation_code,
          status:            r.status,
          date:              r.date,
          time:              r.time,
          guests:            r.guests,
          occasion:          r.occasion,
          notes:             r.notes,
          branch_id:         r.branch_id,
          branch_name:       r.branch&.name,
          user_id:           r.user_id,
          username:          r.user&.username,
          confirmed_at:      r.confirmed_at,
          cancelled_at:      r.cancelled_at,
          created_at:        r.created_at
        }
      end
    end
  end
end