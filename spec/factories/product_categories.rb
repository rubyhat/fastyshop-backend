FactoryBot.define do
  factory :product_category do
    title { Faker::Lorem.word }
    parent_id { nil }
    level { 0 }
    position { 0 }
    status { "published" }
    published_at { Time.current }

    association :shop

    trait :draft do
      status { "draft" }
      published_at { nil }
    end

    trait :archived do
      status { "archived" }
      archived_at { Time.current }
    end
  end
end
