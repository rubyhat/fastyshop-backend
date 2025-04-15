FactoryBot.define do
  factory :legal_profile do
    company_name { Faker::Name.name }
    tax_id { SecureRandom.hex(6) }
    country_code { "KZ" }
    legal_address { Faker::Address.full_address }
    legal_form { "LLC" }
    is_verified { true }

    association :seller_profile
  end
end
