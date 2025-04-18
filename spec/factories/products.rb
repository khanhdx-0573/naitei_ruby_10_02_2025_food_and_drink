FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    price { Faker::Commerce.price(range: 1..49) }
    description { Faker::Lorem.sentence }
  end
end
