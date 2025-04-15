FactoryBot.define do
  factory :seller_profile do
    association :user
    display_name { Faker::Name.name }
    description { Faker::Lorem.paragraph }
  end
end
