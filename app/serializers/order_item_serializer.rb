class OrderItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :unit_price
  belongs_to :product, serializer: ProductSerializer
end
