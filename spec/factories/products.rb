FactoryBot.define do
  factory :product do
    title { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence }
    price { Faker::Commerce.price }
    position { Faker::Number.between(from: 1, to: 10) }
    product_type { "product" }
    is_active { true }

    association :shop
    association :product_category
  end
end
