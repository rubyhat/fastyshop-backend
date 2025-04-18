FactoryBot.define do
  factory :shop do
    title { Faker::Lorem.word }
    contact_phone { "77011234567" }
    contact_email { Faker::Internet.email }
    physical_address { Faker::Address.full_address }
    is_active { true }
    shop_type { "online" }

    association :seller_profile
    # Явно связываем legal_profile с этим seller_profile
    legal_profile { association :legal_profile, seller_profile: seller_profile }
    association :shop_category
  end
end
