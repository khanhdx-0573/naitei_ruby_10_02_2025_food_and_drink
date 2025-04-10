class ProductsController < ApplicationController
  before_action :find_product, only: :show
  def show
    authorize! :read, @product
    @reviews = @product.reviews.includes(order: :user)
    @avg_rating = calculate_avg_rating @product.id
  end

  def index
    authorize! :read, Product
    @categories = Category.all
    @q = Product.ransack(params[:q], auth_object: current_user)
    @pagy, @products = pagy Product.with_attached_image
                                   .filtered(params, current_user),
                            limit: Settings.pagy_items
  end
  private
  def find_product
    @product = Product.find_by id: params[:id]
    return if @product

    flash[:danger] = t "product.product_not_found"
    redirect_to root_path
  end

  def calculate_avg_rating product_id
    reviews = Review.by_product_id product_id
    return 0 if reviews.blank?

    reviews.average(:rating).to_f.round(1)
  end
end
