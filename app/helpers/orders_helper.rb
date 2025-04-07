module OrdersHelper
  def cart_items_count
    return session[:cart]&.count || 0 unless user_signed_in?

    current_user.orders
                .by_status(:draft)
                .joins(order_items: :product)
                .where(products: {deleted_at: nil})
                .count
  end
end
