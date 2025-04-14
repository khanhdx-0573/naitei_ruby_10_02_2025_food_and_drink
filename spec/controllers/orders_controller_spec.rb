require "rails_helper"

RSpec.describe OrdersController, type: :controller do
  let(:user) { create(:user) }
  let(:product) { create(:product) }
  let(:order) { create(:order, user: user, status: :draft) }
  let(:order_item) { create(:order_item, order: order, product: product) }
  let(:delivered_order) { create(:order, user: user, status: :delivered) }
  let(:confirmed_order) { create(:order, user: user, status: :confirmed) }
  let(:pending_order) { create(:order, user: user, status: :pending) }
  let(:review) { create(:review, product: product, order: delivered_order) }

  before do
    sign_in user
    allow(controller).to receive(:authorize!).and_return(true)
  end

  describe "POST #create" do
    context "when user is signed in" do
      context "when add_to_cart is successful" do
        before do
          expect_any_instance_of(Cart).to receive(:add_to_cart)
            .with(product.id.to_s, 1).and_return(true)
          post :create, params: { product_id: product.id, quantity: 1 }
        end

        it "redirects to product page" do
          expect(response).to redirect_to(product_path(product))
        end

        it "sets a success flash message" do
          expect(flash[:success]).to eq(I18n.t("order.add_success"))
        end
      end

      context "when add_to_cart fails" do
        before do
          allow_any_instance_of(Cart).to receive(:add_to_cart)
            .with(product.id.to_s, 1).and_return(false)
          post :create, params: { product_id: product.id, quantity: 1 }
        end

        it "redirects to product page" do
          expect(response).to redirect_to(product_path(product))
        end

        it "sets a danger flash message" do
          expect(flash[:danger]).to eq(I18n.t("order.add_failed"))
        end
      end

      context "with invalid input" do
        before { post :create, params: { product_id: -1, quantity: -5 } }

        it "sets a danger flash message" do
          expect(flash[:danger]).to eq(I18n.t("order.add_failed"))
        end
      end
    end

    context "when user is not signed in" do
      before { sign_out user }
      context "when add_to_cart_not_logged_in is successful" do
        before do
          expect_any_instance_of(Cart).to receive(:add_to_cart_not_logged_in)
            .with(product.id.to_s, 1).and_return(true)
          post :create, params: { product_id: product.id, quantity: 1 }
        end

        it "redirects to product page" do
          expect(response).to redirect_to(product_path(product))
        end

        it "sets a success flash message" do
          expect(flash[:success]).to eq(I18n.t("order.add_success"))
        end
      end

      context "when add_to_cart_not_logged_in fails" do
        before do
          allow_any_instance_of(Cart).to receive(:add_to_cart_not_logged_in)
            .with(product.id.to_s, 1).and_return(false)
          post :create, params: { product_id: product.id, quantity: 1 }
        end

        it "redirects to product page" do
          expect(response).to redirect_to(product_path(product))
        end

        it "sets a danger flash message" do
          expect(flash[:danger]).to eq(I18n.t("order.add_failed"))
        end
      end

      context "with invalid input" do
        before { post :create, params: { product_id: -1, quantity: -5 } }

        it "sets a danger flash message" do
          expect(flash[:danger]).to eq(I18n.t("order.add_failed"))
        end
      end
    end
  end
  describe "GET #show_cart" do
    context "when user has a draft order" do
      before do
        order_item
        get :show_cart, params: { user_id: user.id }
      end

      it "assigns the draft order to @order" do
        expect(assigns(:order)).to eq(order)
      end

      it "assigns the order items to @order_items" do
        expect(assigns(:order_items)).to eq([order_item])
      end

      it "assigns the products to @products" do
        expect(assigns(:products)).to eq([product])
      end

      it "assigns the total price to @total_price" do
        expect(assigns(:total_price)).to eq(order_item.quantity * order_item.unit_price)
      end

      it "renders the show_cart template" do
        expect(response).to render_template(:show_cart)
      end
    end

    context "when user does not have a draft order" do
      before do
        get :show_cart, params: { user_id: user.id }
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("order.cart_empty"))
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET #show_guest_cart" do
    before { sign_out user }
    context "when session has cart items" do
      before do
        session[:cart] = { product.id.to_s => { "quantity" => 3 } }
        get :show_guest_cart
      end

      it "assigns the products to @products" do
        expect(assigns(:products)).to eq([product])
      end

      it "assigns the order items to @order_items" do
        expect(assigns(:order_items).first.product_id).to eq(product.id)
        expect(assigns(:order_items).first.quantity).to eq(3)
        expect(assigns(:order_items).first.unit_price).to eq(product.price)
      end

      it "assigns the total price to @total_price" do
        expect(assigns(:total_price)).to eq(3 * product.price)
      end

      it "renders the show_cart template" do
        expect(response).to render_template(:show_cart)
      end
    end

    context "when session does not have cart items" do
      before { get :show_guest_cart }

      it "assigns an empty array to @products" do
        expect(assigns(:products)).to be_empty
      end

      it "assigns an empty array to @order_items" do
        expect(assigns(:order_items)).to be_empty
      end

      it "assigns 0 to @total_price" do
        expect(assigns(:total_price)).to eq(0)
      end

      it "renders the show_cart template" do
        expect(response).to render_template(:show_cart)
      end
    end
  end

  describe "GET #edit" do
    before do
      order_item
      get :edit, params: { id: order.id }
    end

    it "assigns the draft order to @order" do
      expect(assigns(:order)).to eq(order)
    end

    it "assigns the order items to @order_items" do
      expect(assigns(:order_items)).to eq([order_item])
    end

    it "assigns the products to @products" do
      expect(assigns(:products)).to eq([product])
    end

    it "assigns the total price to @total_price" do
      expect(assigns(:total_price)).to eq(order_item.quantity * order_item.unit_price)
    end

    it "renders the edit template" do
      expect(response).to render_template(:edit)
    end

    context "when the order is not a draft" do
      let(:order) { create(:order, user: user, status: :pending) }
      before { get :edit, params: { id: order.id } }

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("order.not_found"))
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH #update" do
    context "when update is successful" do
      before do
        patch :update, params: { id: order.id, order: { address: "New Address" } }
      end

      it "updates the order status to pending" do
        order.reload
        expect(order.status).to eq("pending")
      end

      it "sets a success flash message" do
        expect(flash[:success]).to eq(I18n.t("order.pending"))
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end

    context "when update fails" do
      before do
        allow_any_instance_of(Order).to receive(:update).and_return(false)
        order_item
        patch :update, params: { id: order.id, order: { address: nil } }
      end

      it "assigns the order items to @order_items" do
        expect(assigns(:order_items)).to eq([order_item])
      end

      it "assigns the products to @products" do
        expect(assigns(:products)).to eq([product])
      end

      it "assigns the total price to @total_price" do
        expect(assigns(:total_price)).to eq(order_item.quantity * order_item.unit_price)
      end

      it "renders the edit template" do
        expect(response).to render_template(:edit)
      end
    end

    context "when the order is not a draft" do
      let(:order) { create(:order, user: user, status: :pending) }
      before { patch :update, params: { id: order.id, order: { address: "New Address" } } }

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("order.not_found"))
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET #view_history" do
    context "when the user visits view_history" do
      before do
        get :view_history, params: { user_id: user.id }
      end

      it "renders the view_history template" do
        expect(response).to render_template(:view_history)
      end
    end

    context "when filtering by status" do
      before do
        get :view_history, params: { user_id: user.id, status: :confirmed }
      end

      it "assigns filtered orders to @orders" do
        expect(assigns(:orders)).to eq([confirmed_order])
      end
    end
  end

  describe "PATCH #cancel_order" do
    context "when cancellation is successful" do
      before do
        patch :cancel_order, params: { id: pending_order.id }
      end

      it "updates the order status to canceled" do
        pending_order.reload
        expect(pending_order.status).to eq("canceled")
      end

      it "sets a success flash message" do
        expect(flash[:success]).to eq(I18n.t("order.cancel_success"))
      end

      it "redirects to the view_history path" do
        expect(response).to redirect_to(view_history_path(user.id))
      end
    end

    context "when cancellation fails" do
      before do
        allow_any_instance_of(Order).to receive(:update).with(status: :canceled).and_return(false)
        patch :cancel_order, params: { id: pending_order.id }
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("order.cancel_failed"))
      end

      it "redirects to the view_history path" do
        expect(response).to redirect_to(view_history_path(user.id))
      end
    end

    context "when the order is not pending" do
      before { patch :cancel_order, params: { id: order.id } }

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("order.not_found"))
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET #review_product" do
    before do
      get :review_product, params: { id: delivered_order.id, product_id: product.id }
    end

    it "assigns a new review to @review" do
      expect(assigns(:review)).to be_a_new(Review)
    end

    it "renders the review_product template" do
      expect(response).to render_template(:review_product)
    end

    context "when the order is not delivered" do
      before { get :review_product, params: { id: order.id, product_id: product.id } }

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("order.not_found"))
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end

    context "when the product does not exist" do
      before { get :review_product, params: { id: delivered_order.id, product_id: 999 } }

      it "sets a danger flash message for product not found" do
        expect(flash[:danger]).to eq(I18n.t("product.product_not_found"))
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end

    context "when a review already exists for the product and order" do
      let!(:existing_review) { create(:review, product: product, order: delivered_order) }
      before { get :review_product, params: { id: delivered_order.id, product_id: product.id } }

      it "sets a danger flash message for existing review" do
        expect(flash[:danger]).to eq(I18n.t("review.review_exist"))
      end

      it "redirects to the view_history path" do
        expect(response).to redirect_to(view_history_path(user.id))
      end
    end
  end

  describe "POST #review_product_post" do
    let(:review_params) { { rating: 5, comment: "Great product!", product_id: product.id, order_id: delivered_order.id } }

    context "when review creation is successful" do
      before do
        post :review_product_post, params: { id: delivered_order.id, product_id: product.id, review: review_params }
      end

      it "creates a new review" do
        expect(Review.count).to eq(1)
      end

      it "sets a success flash message" do
        expect(flash[:success]).to eq(I18n.t("review.review_success"))
      end

      it "redirects to the view_history path" do
        expect(response).to redirect_to(view_history_path(user.id))
      end
    end

    context "when review creation fails" do
      before do
        allow_any_instance_of(Review).to receive(:save).and_return(false)
        post :review_product_post, params: { id: delivered_order.id, product_id: product.id, review: review_params }
      end

      it "renders the review_product template" do
        expect(response).to render_template(:review_product)
      end
    end

    context "when the order is not delivered" do
      before { post :review_product_post, params: { id: order.id, product_id: product.id, review: review_params } }

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("order.not_found"))
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end

    context "when the product does not exist" do
      let(:review_params) { { rating: 5, comment: "Great product!", product_id: -1, order_id: delivered_order.id } }
      before { post :review_product_post, params: { id: delivered_order.id, product_id: -1, review: review_params } }

      it "sets a danger flash message for product not found" do
        expect(flash[:danger]).to eq(I18n.t("product.product_not_found"))
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end

    context "when a review already exists for the product and order" do
      let!(:existing_review) { create(:review, product: product, order: delivered_order) }
      before { post :review_product_post, params: { id: delivered_order.id, product_id: product.id, review: review_params } }

      it "sets a danger flash message for existing review" do
        expect(flash[:danger]).to eq(I18n.t("review.review_exist"))
      end

      it "redirects to the view_history path" do
        expect(response).to redirect_to(view_history_path(user.id))
      end
    end
  end
end
