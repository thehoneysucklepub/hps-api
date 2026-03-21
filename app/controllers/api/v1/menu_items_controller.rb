module Api
  module V1
    class MenuItemsController < ApplicationController
      before_action :set_category
      before_action :set_item, only: [:show, :update, :destroy]

      def index
        items = @category.menu_items.ordered
        render json: { success: true, menu_items: items }
      end

      def show
        render json: { success: true, menu_item: @item }
      end

      def create
        require_admin!
        item = @category.menu_items.create!(item_params)
        render json: { success: true, menu_item: item }, status: :created
      end

      def update
        require_admin!
        @item.update!(item_params)
        render json: { success: true, menu_item: @item }
      end

      def destroy
        require_admin!
        @item.destroy!
        render json: { success: true, message: "Item deleted" }
      end

      private

      def set_category
        @category = MenuCategory.find(params[:menu_category_id])
      end

      def set_item
        @item = @category.menu_items.find(params[:id])
      end

      def item_params
        params.permit(:name, :description, :price, :image_url, :available, :position)
      end
    end
  end
end