module Api
  module V1
    class AuthController < ApplicationController

      def login
        result = AuthService.login(
          username_or_email: params[:username_or_email],
          password: params[:password],
          ip: request.remote_ip,
          user_agent: request.user_agent
        )

        json_success({
          access_token:  result[:access_token],
          refresh_token: result[:refresh_token],
          user: user_payload(result[:user])
        })
      end

      def refresh
        result = AuthService.refresh(
          token_string: params[:refresh_token],
          ip: request.remote_ip
        )

        json_success({
          access_token:  result[:access_token],
          refresh_token: result[:refresh_token]
        })
      end

      def logout
        AuthService.logout(token_string: params[:refresh_token])
        json_success({ message: "Logged out successfully" })
      end

      def me
        authenticate_user!
        json_success({ user: user_payload(current_user) })
      end

      private

      def user_payload(user)
        {
          id:            user.id,
          username:      user.username,
          email:         user.email,
          role:          user.role,
          first_name:    user.first_name,
          last_name:     user.last_name,
          full_name:     user.full_name,
          avatar_url:    user.avatar_url,
          branch_id:     user.branch_id,
          created_at:    user.created_at,
          last_login_at: user.last_login_at
        }
      end
    end
  end
end