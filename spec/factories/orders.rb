FactoryBot.define do
  factory :order do
    shipping_address { Faker::Address.full_address }
    phone_number { "0987654321" }
    total_price { 100.0 }
    status { :pending }
    user
  end
end
