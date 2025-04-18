FactoryBot.define do
  factory :order do
    association :user
    association :shop

    status { :created }
    delivery_method { :courier }
    payment_method { :cash_on_delivery }

    contact_name { "Тестовый пользователь" }
    contact_phone { "77075554433" }
    delivery_address_text { "Алматы, ул. Толе би, д. 15" }
    total_price { 1500 }
  end
end
