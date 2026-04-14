FactoryBot.define do
  factory :user do
    sequence(:phone) { |n| "770000#{n.to_s.rjust(5, '0')}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password123!" }
    password_confirmation { "Password123!" }
    role { :user }
    country_code { "KZ" }
    account_status { :approved }

    after(:build) do |user|
      next unless %w[KZ RU].include?(user.country_code)

      Country.find_or_create_by!(code: user.country_code) do |country|
        country.name = user.country_code == "RU" ? "Россия" : "Казахстан"
        country.phone_prefix = "+7"
      end
    end
  end
end
