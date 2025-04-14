FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { "password" }
    password_confirmation { "password" }
    admin { false }
    confirmed_at { Time.current }

    trait :admin do
      admin { true }
    end
  end
end
