class Order < ApplicationRecord
  ORDER_PARAMS = %i(shipping_address phone_number).freeze
  ORDER_UPDATE_PARAMS = %i(status).freeze
  BLOCKED_STATUS = {
    canceled: :delivered
  }.freeze
  enum status: {
    draft: -1,
    pending: 0,
    confirmed: 1,
    delivered: 2,
    canceled: 3
  }, _prefix: true

  validates :status, presence: true,
            inclusion: {in: statuses.keys}
  validates :total_price, presence: true,
            numericality: {greater_than_or_equal_to: Settings.min_price}
  validates :shipping_address, presence: true, allow_nil: true,
            length: {maximum: Settings.max_address_length}
  validates :phone_number, presence: true, allow_nil: true,
            length: {maximum: Settings.max_phone_length},
            format: {with: Regexp.new(Settings.valid_phone_regex)}
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :products, ->{with_deleted}, through: :order_items
  has_many :reviews, dependent: :destroy

  scope :by_user_id, ->(user_id){where user_id:}
  scope :not_draft, ->{where.not(status: :draft)}
  scope :order_by_created_at, ->{order created_at: :desc}
  scope :by_status, lambda {|status|
    where(status:) if status.present?
  }
  scope :filtered, lambda {|params|
    ransack(params[:q]).result
  }
  ransacker :created_at, type: :date do
    Arel.sql("DATE(created_at)")
  end

  def calculate_total_price
    order_items.sum do |order_item|
      order_item.quantity * order_item.unit_price
    end
  end

  def update_total_price!
    total = calculate_total_price
    update!(total_price: total)
  end

  def self.ransackable_attributes _auth_object = nil
    %w(status created_at)
  end

  def self.ransackable_scopes _auth_object = nil
    %i(by_status)
  end

  def self.ransackable_associations _auth_object = nil
    %w(order_items products reviews user)
  end
end
