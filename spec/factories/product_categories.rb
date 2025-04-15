FactoryBot.define do
  factory :product_category do
    title { Faker::Lorem.word }
    parent_id { nil }
    level { 0 }
    position { 0 }
    is_active { true }

    association :shop
  end
end
