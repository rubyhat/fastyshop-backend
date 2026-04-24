FactoryBot.define do
  factory :seller_profile do
    association :user
    sequence(:display_name) { |n| "Seller Brand #{n}" }
    description { Faker::Lorem.paragraph }
  end
end
