FactoryBot.define do
  factory :user_address do
    association :user
    label { "Дом" }
    contact_name { "Тестовый пользователь" }
    contact_phone { "77070000000" }
    country_code { "KZ" }
    city { "Алматы" }
    street { "Абая" }
    house { "1" }
    apartment { "10" }
    is_default { false }
  end
end
