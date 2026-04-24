FactoryBot.define do
  factory :cart do
    association :user
    association :shop
    status { "active" }
    expired_at { 30.days.from_now }

    trait :converted do
      status { "converted" }
      converted_at { Time.current }
    end
  end
end
