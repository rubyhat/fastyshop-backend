FactoryBot.define do
  factory :product_property do
    title { Faker::Commerce.material }
    value_type { "string" }
    source_type { "user" }

    association :user
  end
end
