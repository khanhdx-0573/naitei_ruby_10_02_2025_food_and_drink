class Admin::ProductsController < ApplicationController
  before_action :authorize_admin
  before_action :find_product, only: %i(update edit destroy)
  before_action :set_categories, only: %i(new edit)

  def index
    @pagy, @products = pagy Product.with_attached_image
                                   .by_date_updated
                                   .includes(:categories),
                            limit: Settings.pagy_items
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new product_params
    @product.image.attach params.dig(:product, :image)
    if @product.save
      flash[:success] = t "product.create_success"
      redirect_to admin_products_path
    else
      set_categories
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if params.dig(:product, :image).present?
      @product.image.attach params.dig(:product, :image)
    end
    if @product.update product_params
      flash[:success] = t "product.update_success"
      redirect_to admin_products_path
    else
      set_categories
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.update deleted_at: Time.zone.now
      flash[:success] = t "product.delete_success"
    else
      flash[:danger] = t "product.delete_fail"
    end
    redirect_to admin_products_path
  end

  private
  def find_product
    @product = Product.find_by id: params[:id]
    return if @product

    flash[:danger] = t "product.product_not_found"
    redirect_to admin_products_path
  end

  def product_params
    params.require(:product).permit Product::PRODUCT_PARAMS
  end

  def set_categories
    @categories = Category.all
  end
end
