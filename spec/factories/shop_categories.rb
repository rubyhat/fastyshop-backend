FactoryBot.define do
  factory :shop_category do
    sequence(:title) { |n| "Flowers #{n}" }
    sequence(:name) { |n| "flowers-#{n}" }
    description { Faker::Lorem.paragraph }
    position { 1 }
    is_active { true }
  end
end
