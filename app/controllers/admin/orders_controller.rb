class Admin::OrdersController < ApplicationController
  before_action :authorize_admin
  before_action :find_order, only: %i(update destroy)
  def index
    @pagy, @orders = pagy Order
                     .includes(:order_items)
                     .includes(:products)
                     .includes(:user)
                     .not_draft,
                          limit: Settings.pagy_items
    @orders = @orders.by_date(params[:date]).by_status(params[:status])
  end

  def update
    if check_valid_status_update == false
      flash[:danger] = t "order.update_fail"
      redirect_to admin_orders_path
      return
    end
    if @order.update edit_order_params
      flash[:success] = t "order.update_success"
    else
      flash[:danger] = t "order.update_fail"
    end
    redirect_to admin_orders_path
  end

  def destroy
    if @order.destroy
      flash[:success] = t "order.delete_success"
    else
      flash[:danger] = t "order.delete_fail"
    end
    redirect_to admin_orders_path
  end

  private
  def find_order
    @order = Order.find_by id: params[:id]
    return if @order

    flash[:danger] = t "order.not_found"
    redirect_to admin_orders_path
  end

  def edit_order_params
    params.require(:order).permit Order::ORDER_UPDATE_PARAMS
  end

  def check_valid_status_update
    status_param = edit_order_params[:status]
    if Order::BLOCKED_STATUS[status_param.to_sym] == @order.status.to_sym
      return false
    end
    return false if Order.statuses[@order.status] > Order.statuses[status_param]

    true
  end
end
