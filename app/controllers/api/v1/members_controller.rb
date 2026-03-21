module Api
  module V1
    class MembersController < ApplicationController

      def register
        user = User.create!(
          username:  params[:username],
          email:     params[:email],
          password:  params[:password],
          role:      "member",
          first_name: params[:first_name],
          last_name:  params[:last_name],
          phone:      params[:phone],
          active:     true
        )
        MemberProfile.create!(user: user)
        result = AuthService.login(
          username_or_email: params[:username],
          password:          params[:password],
          ip:                request.remote_ip
        )
        render json: {
          success:       true,
          message:       "Welcome to The Honeysuckle Pub!",
          access_token:  result[:access_token],
          refresh_token: result[:refresh_token],
          user:          member_json(user)
        }, status: :created
      end

      def profile
        authenticate_user!
        render json: { success: true, user: member_json(current_user) }
      end

      def update_profile
        authenticate_user!
        current_user.update!(
          first_name: params[:first_name],
          last_name:  params[:last_name],
          phone:      params[:phone],
          avatar_url: params[:avatar_url]
        )
        profile = current_user.member_profile ||
                  current_user.create_member_profile
        profile.update!(
          date_of_birth:          params[:date_of_birth],
          favorite_branch:        params[:favorite_branch],
          bio:                    params[:bio],
          notifications_enabled:  params.fetch(:notifications_enabled, true),
          marketing_emails:       params.fetch(:marketing_emails, false)
        )
        render json: { success: true, user: member_json(current_user) }
      end

      def dashboard
        authenticate_user!
        upcoming_bookings     = current_user.event_bookings
                                            .includes(:event, :branch)
                                            .upcoming
                                            .limit(5)
        upcoming_reservations = current_user.table_reservations
                                            .includes(:branch)
                                            .upcoming
                                            .limit(5)
        bookmarked            = current_user.bookmarked_events
                                            .where("date_start >= ?", Date.today)
                                            .limit(5)
        render json: {
          success: true,
          dashboard: {
            user:                 member_json(current_user),
            upcoming_bookings:    upcoming_bookings.map  { |b| booking_summary(b) },
            upcoming_reservations: upcoming_reservations.map { |r| reservation_summary(r) },
            bookmarked_events:    bookmarked,
            stats: {
              total_bookings:     current_user.event_bookings.count,
              total_reservations: current_user.table_reservations.count,
              bookmarks:          current_user.event_bookmarks.count
            }
          }
        }
      end

      private

      def member_json(user)
        profile = user.member_profile
        {
          id:          user.id,
          username:    user.username,
          email:       user.email,
          full_name:   user.full_name,
          first_name:  user.first_name,
          last_name:   user.last_name,
          phone:       user.phone,
          avatar_url:  user.avatar_url,
          role:        user.role,
          created_at:  user.created_at,
          profile: profile ? {
            date_of_birth:         profile.date_of_birth,
            favorite_branch:       profile.favorite_branch,
            bio:                   profile.bio,
            notifications_enabled: profile.notifications_enabled,
            marketing_emails:      profile.marketing_emails
          } : nil
        }
      end

      def booking_summary(b)
        {
          id:                b.id,
          confirmation_code: b.confirmation_code,
          event_title:       b.event&.title,
          event_date:        b.event&.date_start,
          event_time:        b.event&.time_local,
          branch_name:       b.branch&.name,
          guests:            b.guests,
          status:            b.status
        }
      end

      def reservation_summary(r)
        {
          id:                r.id,
          confirmation_code: r.confirmation_code,
          branch_name:       r.branch&.name,
          date:              r.date,
          time:              r.time,
          guests:            r.guests,
          status:            r.status
        }
      end
    end
  end
end