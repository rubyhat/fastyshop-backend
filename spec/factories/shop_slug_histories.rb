FactoryBot.define do
  factory :shop_slug_history do
    association :shop
    sequence(:slug) { |n| "old-shop-slug-#{n}" }
  end
end
