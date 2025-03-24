Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    root "static_pages#home"

    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"

    resources :products
    resources :orders
    get "/cart", to: "orders#show_guest_cart", as: "guest_cart"
    get "/cart/:user_id", to: "orders#show_cart", as: "cart"

    resources :order_items, only: %i(update destroy)
    patch "/guest_cart_items/:product_id", to: "order_items#update_guest_cart_item", as: "update_guest_cart_item"
    delete "/guest_cart_items/:product_id", to: "order_items#remove_guest_cart_item", as: "remove_guest_cart_item"
  end
end
