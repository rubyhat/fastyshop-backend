FactoryBot.define do
  factory :shop_category do
    title { "Flowers" }
    name { "flowers" }
    description { Faker::Lorem.paragraph }
    position { 1 }
    is_active { true }
  end
end
