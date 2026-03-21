module Api
  module V1
    class HealthController < ApplicationController
      def check
        json_success({
          status: "ok",
          time: Time.now.utc.iso8601,
          env: Rails.env,
          version: "1.0.0"
        })
      end
    end
  end
end