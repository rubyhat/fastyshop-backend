FactoryBot.define do
  factory :shop do
    title { Faker::Lorem.word }
    contact_phone { "77011234567" }
    contact_email { Faker::Internet.email }
    physical_address { Faker::Address.full_address }
    is_active { true }

    association :seller_profile
    association :legal_profile
    association :shop_category
    association :product_categories
  end
end
