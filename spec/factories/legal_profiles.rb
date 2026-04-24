FactoryBot.define do
  factory :legal_profile do
    legal_name { "TOO Example Trade" }
    country_code { "KZ" }
    legal_address { Faker::Address.full_address }
    legal_form_code { "limited_liability_partnership" }
    registration_number_type { "bin" }
    sequence(:registration_number) { |n| "12#{n.to_s.rjust(10, '0')}" }
    verification_status { :draft }
    moderation_comment { nil }

    association :seller_profile

    trait :approved do
      verification_status { :approved }
    end

    trait :draft do
      verification_status { :draft }
    end

    trait :pending_review do
      verification_status { :pending_review }
    end

    trait :rejected do
      verification_status { :rejected }
      moderation_comment { "Нужно исправить данные" }
    end

    trait :self_employed do
      legal_name { "Иванов Иван Иванович" }
      legal_form_code { "self_employed" }
      registration_number_type { "iin" }
      sequence(:registration_number) { |n| "98#{n.to_s.rjust(10, '0')}" }
    end

    trait :individual_entrepreneur do
      legal_name { "ИП Иванов Иван Иванович" }
      legal_form_code { "individual_entrepreneur" }
      registration_number_type { "iin" }
      sequence(:registration_number) { |n| "87#{n.to_s.rjust(10, '0')}" }
    end
  end
end
