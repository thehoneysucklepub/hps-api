module Api
  module V1
    class MenuCategoriesController < ApplicationController
      before_action :set_category, only: [:show, :update, :destroy]

      def index
        categories = MenuCategory.active.ordered.includes(:menu_items)
        render json: { success: true, menu_categories: categories.map { |c| category_json(c) } }
      end

      def show
        render json: { success: true, menu_category: category_json(@category) }
      end

      def create
        require_admin!
        category = MenuCategory.create!(category_params)
        audit(action: "create_menu_category", resource: "MenuCategory", resource_id: category.id)
        render json: { success: true, menu_category: category_json(category) }, status: :created
      end

      def update
        require_admin!
        @category.update!(category_params)
        render json: { success: true, menu_category: category_json(@category) }
      end

      def destroy
        require_admin!
        @category.destroy!
        render json: { success: true, message: "Category deleted" }
      end

      private

      def set_category
        @category = MenuCategory.find(params[:id])
      end

      def category_params
        params.permit(:name, :menu_type, :position, :active)
      end

      def category_json(category)
        {
          id:         category.id,
          name:       category.name,
          menu_type:  category.menu_type,
          position:   category.position,
          active:     category.active,
          menu_items: category.menu_items.available.ordered.map { |i| item_json(i) }
        }
      end

      def item_json(item)
        {
          id:          item.id,
          name:        item.name,
          description: item.description,
          price:       item.price,
          image_url:   item.image_url,
          available:   item.available,
          position:    item.position
        }
      end
    end
  end
end