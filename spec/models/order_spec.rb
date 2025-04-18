require "rails_helper"

RSpec.describe Order, type: :model do
  describe "validations" do
    let(:valid_total_price) { Settings.min_price + 1 }
    let(:valid_shipping_address) { "123 Main Street" }
    let(:long_shipping_address) { "a" * (Settings.max_address_length + 1) }
    let(:valid_phone_number) { "0987654321" }
    let(:long_phone_number) { "1" * (Settings.max_phone_length + 1) }

    context "total price" do
      it "is invalid without total_price" do
        order = build(:order, total_price: nil)
        expect(order).to be_invalid
      end

      it "is invalid when less than minimum price" do
        order = build(:order, total_price: Settings.min_price - 1)
        expect(order).to be_invalid
      end

      it "is valid when equal to minimum price" do
        order = build(:order, total_price: Settings.min_price)
        expect(order).to be_valid
      end

      it "is valid when greater than minimum price" do
        order = build(:order, total_price: valid_total_price)
        expect(order).to be_valid
      end
    end

    context "shipping address" do
      it "is invalid when too long" do
        order = build(:order, shipping_address: long_shipping_address)
        expect(order).to be_invalid
      end

      it "is valid with proper address" do
        order = build(:order, shipping_address: valid_shipping_address)
        expect(order).to be_valid
      end

      it "is valid when nil for draft order" do
        order = build(:order, status: "draft", shipping_address: nil)
        expect(order).to be_valid
      end
    end

    context "phone number" do
      it "is invalid when too long" do
        order = build(:order, phone_number: long_phone_number)
        expect(order).to be_invalid
      end

      it "is invalid with wrong format" do
        order = build(:order, phone_number: "abc123")
        expect(order).to be_invalid
      end

      it "is valid with proper phone_number" do
        order = build(:order, phone_number: valid_phone_number)
        expect(order).to be_valid
      end
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:order_items).dependent(:destroy) }
    it { should have_many(:products).through(:order_items) }
    it { should have_many(:reviews).dependent(:destroy) }
  end

  describe "enums" do
    it "defines the correct enum values" do
      expect(Order.statuses).to eq({
        "draft" => -1,
        "pending" => 0,
        "confirmed" => 1,
        "delivered" => 2,
        "canceled" => 3
      })
    end
  end

  describe "scopes" do
    let!(:order1) { create(:order, status: :draft) }
    let!(:order2) { create(:order, status: :pending) }
    let!(:order3) { create(:order, status: :confirmed) }

    context "basic scopes" do
      it "returns orders by user_id" do
        expect(Order.by_user_id(order1.user_id)).to include(order1)
      end

      it "does not return draft orders in not_draft" do
        expect(Order.not_draft).not_to include(order1)
      end

      it "returns pending and confirmed orders in not_draft" do
        expect(Order.not_draft).to include(order2, order3)
      end

      it "orders by created_at in descending order" do
        expect(Order.order_by_created_at).to eq([order3, order2, order1])
      end

      it "filters orders by status: pending" do
        expect(Order.by_status(:pending)).to include(order2)
      end

      it "does not filter orders by status: pending" do
        expect(Order.by_status(:pending)).not_to include(order1, order3)
      end
    end

    context "filtered (Ransack)" do
      let(:order1) { create(:order, status: :pending, created_at: 2.days.ago) }
      let(:order2) { create(:order, status: :confirmed, created_at: 1.day.ago) }
      let(:order3) { create(:order, status: :delivered, created_at: Time.now) }
      let(:order4) { create(:order, status: :confirmed, created_at: 3.days.ago) }
      let(:order5) { create(:order, status: :pending, created_at: 4.days.ago) }

      it "returns all orders when no params are provided" do
        expect(Order.filtered({})).to match_array([order1, order2, order3, order4, order5])
      end

      it "filters orders by created_at" do
        params = { q: { created_at_eq: 1.day.ago.to_date } }
        expect(Order.filtered(params)).to match_array([order2])
      end
    end
  end

  describe "methods" do
    context "#calculate_total_price" do
      let(:order) { create(:order) }
      let!(:order_item1) { create(:order_item, order: order, quantity: 2, unit_price: 10) }
      let!(:order_item2) { create(:order_item, order: order, quantity: 3, unit_price: 5) }

      it "calculates the total price" do
        expect(order.calculate_total_price).to eq((2 * 10) + (3 * 5))
      end
    end

    context "#update_total_price!" do
      let(:order) { create(:order) }
      let!(:order_item1) { create(:order_item, order: order, quantity: 2, unit_price: 10) }
      let!(:order_item2) { create(:order_item, order: order, quantity: 3, unit_price: 5) }
      let(:expected_total) { (2 * 10) + (3 * 5) }
      before do
        order.update_total_price!
      end
      it "updates the total price" do
        expect(order.total_price).to eq(expected_total)
      end
    end

    context ".ransackable_attributes" do
      it "returns the list of ransackable attributes" do
        expect(Order.ransackable_attributes).to eq(%w(status created_at))
      end
    end

    context ".ransackable_scopes" do
      it "returns the list of ransackable scopes" do
        expect(Order.ransackable_scopes).to eq(%i(by_status))
      end
    end

    context ".ransackable_associations" do
      it "returns the list of ransackable associations" do
        expect(Order.ransackable_associations).to eq(%w(order_items products reviews user))
      end
    end
  end
end
