FactoryBot.define do
  factory :product do
    title { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence }
    price { Faker::Commerce.price }
    position { Faker::Number.between(from: 1, to: 10) }
    product_type { "physical" }
    status { "published" }
    published_at { Time.current }
    stock_quantity { 10 }

    association :shop
    product_category { association :product_category, shop: shop }

    trait :draft do
      status { "draft" }
      published_at { nil }
    end

    trait :archived do
      status { "archived" }
      archived_at { Time.current }
    end

    trait :digital do
      product_type { "digital" }
    end

    trait :service do
      product_type { "service" }
    end

    trait :without_category do
      product_category { nil }
    end
  end
end
