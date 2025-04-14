FactoryBot.define do
  factory :review do
    rating { Faker::Number.between(from: 1, to: 5) }
    comment { Faker::Lorem.sentence(word_count: 10) }
    order
    product
  end
end
