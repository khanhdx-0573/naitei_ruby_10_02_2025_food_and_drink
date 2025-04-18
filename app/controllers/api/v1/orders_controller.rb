class Api::V1::OrdersController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token
  before_action :find_product, only: %i(review_product review_product_post)
  before_action :find_order_draft, only: %i(edit update)
  before_action :find_order_cancel, only: :cancel_order
  before_action :find_delivered_order,
                only: %i(review_product review_product_post)
  before_action :check_exist_review,
                only: %i(review_product review_product_post)
  def create
    product_id = params[:product_id]
    quantity = params[:quantity].to_i
    cart = Cart.new current_user, session
    add_product_to_cart cart, product_id, quantity
  end

  def show_cart
    @order = Order.find_by user_id: params[:user_id], status: :draft
    if @order.nil?
      render json: {message: t("order.cart_empty")},
             status: :not_found
      return
    end
    @order_items = @order.order_items.includes :product
    serialized_order_items = @order_items.map do |item|
      OrderItemSerializer.new(item)
    end
    render json: {
      order_items: serialized_order_items,
      total_price: @order.total_price
    }, status: :ok
  end

  def edit
    authorize! :edit, @order
    @order_items = @order.order_items.includes :product
    @products = Product.by_ids @order_items.map(&:product_id)
    render json: @order,
           serializer: OrderSerializer,
           include_order_items: true,
           status: :ok
  end

  def update
    authorize! :update, @order
    if @order.update order_params.merge(status: :pending)
      render json: {
        order: @order.as_json(include: :user),
        message: t("order.pending")
      }, status: :ok
    else
      render json: {errors: @order.errors.full_messages},
             status: :unprocessable_entity
    end
  end

  def view_history
    @pagy, @orders = pagy Order.by_user_id(params[:user_id])
                               .includes(order_items: :product)
                               .includes(:user)
                               .not_draft
                               .order_by_created_at,
                          limit: Settings.pagy_items
    authorize! :view_history, @orders.first
    @orders = @orders.by_status(params[:status])
    render json: @orders,
           each_serializer: OrderSerializer,
           include_order_items: true,
           include: ["order_items.product"],
           status: :ok
  end

  def cancel_order
    authorize! :cancel_order, @order
    if @order.update(status: :canceled)
      render json: {message: t("order.cancel_success")}, status: :ok
    else
      render json: {message: t("order.cancel_failed")},
             status: :unprocessable_entity
    end
  end

  def review_product
    authorize! :review_product, @order
    @review = Review.new
    render json: {
             order: OrderSerializer.new(@order),
             product: ProductSerializer.new(@product)
           },
           status: :ok
  end

  def review_product_post
    authorize! :review_product, @order
    rating, comment = review_product_params
    @review = Review.new(
      product_id: params[:product_id],
      order_id: params[:id],
      rating:,
      comment:
    )
    if @review.save
      render json: {message: t("review.review_success")}, status: :created
    else
      render json: {errors: @review.errors.full_messages},
             status: :unprocessable_entity
    end
  end

  private

  def review_product_params
    params.require Review::REVIEW_PARAMS
  end

  def find_product
    @product = Product.find_by(id: params[:product_id])
    return if @product

    render json: {error: t("product.product_not_found")}, status: :not_found
  end

  def find_order
    @order = Order.find_by(id: params[:id] || params[:order_id])
  end

  def find_order_draft
    find_order
    return if @order&.status_draft?

    render json: {error: t("order.not_found")}, status: :not_found
  end

  def find_order_cancel
    find_order
    return if @order&.status_pending?

    render json: {error: t("order.not_found")}, status: :not_found
  end

  def find_delivered_order
    find_order
    return if @order&.status_delivered?

    render json: {error: t("order.not_found")}, status: :not_found
  end

  def check_exist_review
    product_id = params[:product_id]
    order_id = params[:id]
    review = Review.find_by(product_id:, order_id:)
    return if review.blank?

    render json: {error: t("review.review_exist")}, status: :conflict
  end

  def order_params
    params.require Order::ORDER_PARAMS
  end

  def add_product_to_cart cart, product_id, quantity
    success = if user_signed_in?
                cart.add_to_cart(product_id, quantity)
              else
                cart.add_to_cart_not_logged_in(product_id, quantity)
              end
    if success
      render json: {message: t("order.add_success")}, status: :ok
    else
      render json: {message: t("order.add_fail")},
             status: :unprocessable_entity
    end
  end

  def calculate_total_price order_items
    order_items.sum{|item| item.quantity * item.unit_price}
  end

  def add_order_items products_index
    session[:cart].each do |product_id, product_info|
      product = products_index[product_id.to_i]
      @order_items << OrderItem.new(
        product_id:,
        quantity: product_info["quantity"],
        unit_price: product.price
      )
    end
  end
  rescue_from ActionController::ParameterMissing do |e|
    render json: {error: e.message}, status: :bad_request
  end
end
