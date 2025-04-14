FactoryBot.define do
  factory :order_item do
    quantity { Faker::Number.between(from: 1, to: 10) }
    unit_price { Faker::Commerce.price(range: 1.0..50.0) }
    order
    product
  end
end
