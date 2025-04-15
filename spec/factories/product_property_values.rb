FactoryBot.define do
  factory :product_property_value do
    value { Faker::Lorem.word }

    association :product
    association :product_property
  end
end
