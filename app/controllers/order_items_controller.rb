class OrderItemsController < ApplicationController
  before_action :find_order_item, only: %i(update destroy)
  authorize_resource only: %i(update destroy)

  def update
    if @order_item.product.deleted? == false &&
       @order_item.update(update_quantity_params)
      total_price = @order_item.order.calculate_total_price
      render_turbo_stream @order_item, total_price
    else
      flash[:danger] = t "order_item.update_fail"
      redirect_to cart_path(current_user)
    end
  end

  def update_guest_cart_item
    product_id = params[:product_id]
    quantity = params[:quantity].to_i
    return unless check_valid_quantity quantity

    session[:cart][product_id.to_s]["quantity"] = quantity
    total_price = calculate_guest_cart_total
    product = find_product product_id
    return unless product

    new_order_item = OrderItem.new(product_id:, quantity:,
                                   unit_price: product.price,
                                   product:)
    render_turbo_stream new_order_item, total_price
  end

  def destroy
    if @order_item.destroy
      total_price = @order_item.order.calculate_total_price
      render_turbo_stream_destroy @order_item.product, total_price
    else
      flash[:danger] = t "order_items.remove_fail"
      redirect_to root_path
    end
  end

  def remove_guest_cart_item
    product_id = params[:product_id]
    session[:cart].delete(product_id.to_s)

    total_price = calculate_guest_cart_total
    product = find_product product_id
    return unless product

    render_turbo_stream_destroy product, total_price
  end

  private

  def update_quantity_params
    params.require(:order_item).permit OrderItem::UPDATE_QUANTITY_PARAMS
  end

  def find_order_item
    @order_item = OrderItem.find_by id: params[:id]
    return unless @order_item.nil?

    flash[:danger] = t "order_item.not_found"
    redirect_to cart_path(current_user)
  end

  def find_product product_id
    product = Product.find_by id: product_id
    return product if product

    flash[:danger] = t "product.product_not_found"
    redirect_to root_path
  end

  def calculate_guest_cart_total
    product_ids = session[:cart].keys
    products = Product.by_ids product_ids
    products_indexed = products.index_by(&:id)
    session[:cart].sum do |product_id, product_info|
      product = products_indexed[product_id.to_i]
      product_info["quantity"].to_i * product.price
    end
  end

  def check_valid_quantity quantity
    unless quantity < Settings.min_quantity || quantity > Settings.max_quantity
      return true
    end

    flash[:danger] = t "order_item.update_fail"
    redirect_to guest_cart_path
    false
  end

  def render_turbo_stream order_item, total_price
    render turbo_stream: [
      turbo_stream.replace("order_item_#{order_item.product.id}_quantity",
                           partial: "order_items/quantity",
                           locals: {order_item:,
                                    product: order_item.product}),
      turbo_stream.replace("cart_total",
                           partial: "order_items/cart_total",
                           locals: {total_price:})
    ]
  end

  def render_turbo_stream_destroy product, total_price
    render turbo_stream: [
      turbo_stream.remove("order_item_#{product.id}"),
      turbo_stream.replace("cart_total",
                           partial: "order_items/cart_total",
                           locals: {total_price:})
    ]
  end
end
