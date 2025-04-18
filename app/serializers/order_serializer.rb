class OrderSerializer < ActiveModel::Serializer
  attributes :id, :status, :total_price, :shipping_address, :phone_number,
             :created_at, :updated_at

  has_many :order_items, if: ->{instance_options[:include_order_items]}
  belongs_to :user, if: ->{instance_options[:include_user]}
end
