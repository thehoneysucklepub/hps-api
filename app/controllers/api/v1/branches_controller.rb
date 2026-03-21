module Api
  module V1
    class BranchesController < ApplicationController
      before_action :set_branch, only: [:show, :update, :destroy]

      def index
        branches = Branch.active.order(:name)
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

      def set_branch
        @branch = Branch.find(params[:id])
      end

      def branch_params
        params.permit(:name, :slug, :address, :phone_primary, :phone_secondary,
                      :established_year, :description, :active)
      end
    end
  end
end