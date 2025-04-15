FactoryBot.define do
  factory :user do
    phone { Faker::PhoneNumber.phone_number }
    email { Faker::Internet.email }
    password { "Password123!" }
    password_confirmation { "Password123!" }
    role { 2 }
    country_code { "KZ" }
    is_active { true }
  end
end
