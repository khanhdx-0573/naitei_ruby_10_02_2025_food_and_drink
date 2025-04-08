class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new
    define_guest_permissions
    return unless user.persisted?

    define_normal_user_permissions user
    return unless user.admin?

    define_admin_permissions
  end

  private
  def define_guest_permissions
    can :read, Product
    can :create, Order
  end

  def define_normal_user_permissions user
    can :show_cart, Order, user_id: user.id
    can :edit, Order, user_id: user.id
    can :update, Order, user_id: user.id
    can :view_history, Order, user_id: user.id
    can :cancel_order, Order, user_id: user.id
    can :review_product, Order, user_id: user.id

    can :read, OrderItem, order: {user_id: user.id}
    can :update, OrderItem, order: {user_id: user.id}
  end

  def define_admin_permissions
    can :manage_product, Product
    can :manage_order, Order
  end
end
