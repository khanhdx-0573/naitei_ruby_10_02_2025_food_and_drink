Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    devise_for :users, controllers: { registrations: "users/registrations",
    sessions: "users/sessions",
  }
    root "static_pages#home"

    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"

    resources :products
    resources :orders
    get "/cart", to: "orders#show_guest_cart", as: "guest_cart"
    get "/cart/:user_id", to: "orders#show_cart", as: "cart"
    get "/checkout/:id", to: "orders#edit", as: "checkout"
    patch "/checkout/:id", to: "orders#update", as: "checkout_update"
    get "users/:user_id/orders/history", to: "orders#view_history", as: "view_history"
    patch "/orders/cancel_order/:id", to: "orders#cancel_order", as: "cancel_order"
    get "/orders/:id/review-product/:product_id", to: "orders#review_product", as: "review_product"
    post "/orders/:id/review-product/:product_id", to: "orders#review_product_post", as: "review_product_post"

    resources :order_items, only: %i(update destroy)
    patch "/guest_cart_items/:product_id", to: "order_items#update_guest_cart_item", as: "update_guest_cart_item"
    delete "/guest_cart_items/:product_id", to: "order_items#remove_guest_cart_item", as: "remove_guest_cart_item"

    namespace :admin do
      resources :orders
      resources :products
    end
  end
end
