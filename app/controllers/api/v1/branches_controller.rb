module Api
  module V1
    class BranchesController < ApplicationController
      include PublicUrls

      before_action :set_branch, only: [ :show, :update, :destroy ]

      def index
        # ?all=true (admin) also lists inactive venues so they can be re-activated
        branches = params[:all] == "true" && admin_request? ? Branch.ordered : Branch.active.ordered
        branches = branches.where(venue_type: params[:venue_type]) if params[:venue_type].present?
        render json: { success: true, branches: branches }, status: :ok
      end

      def show
        render json: { success: true, branch: @branch }, status: :ok
      end

      def create
        require_admin!
        branch = Branch.create!(branch_params)
        audit(action: "create_branch", resource: "Branch", resource_id: branch.id)
        render json: { success: true, branch: branch }, status: :created
      end

      def update
        require_admin!
        @branch.update!(branch_params)
        audit(action: "update_branch", resource: "Branch", resource_id: @branch.id)
        render json: { success: true, branch: @branch }, status: :ok
      end

      def destroy
        require_super_admin!
        @branch.destroy!
        render json: { success: true, message: "Branch deleted" }, status: :ok
      end

      private

      # Accepts a numeric id or a slug (/branches/osu)
      def set_branch
        @branch = params[:id].to_s.match?(/\A\d+\z/) ? Branch.find(params[:id]) : Branch.find_by!(slug: params[:id])
      end

      def branch_params
        params.permit(:name, :slug, :address, :phone_primary, :phone_secondary,
                      :established_year, :description, :active,
                      :image_url, :tagline, :opening_hours, :map_url, :venue_type, :position,
                      :eyebrow, :story_title, :story, :signatures_title,
                      stats: Branch::SECTION_FIELDS["stats"],
                      features: Branch::SECTION_FIELDS["features"],
                      signatures: Branch::SECTION_FIELDS["signatures"])
      end
    end
  end
end
