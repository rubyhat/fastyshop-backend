FactoryBot.define do
  factory :shop do
    title { Faker::Lorem.word }
    sequence(:slug) { |n| "test-shop-#{n}" }
    description { Faker::Lorem.sentence }
    logo_url { "https://cdn.example.com/shops/logo.png" }
    contact_phone { "77011234567" }
    contact_email { Faker::Internet.email }
    physical_address { Faker::Address.full_address }
    shop_type { "online" }
    status { "active" }

    association :seller_profile
    # Явно связываем legal_profile с этим seller_profile
    legal_profile { association :legal_profile, seller_profile: seller_profile }
    association :shop_category
  end
end
