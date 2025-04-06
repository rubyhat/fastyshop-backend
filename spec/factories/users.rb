FactoryBot.define do
  factory :user do
    phone { "MyString" }
    email { "MyString" }
    password_digest { "MyString" }
    role { 1 }
    country_code { "MyString" }
    is_active { false }
  end
end
