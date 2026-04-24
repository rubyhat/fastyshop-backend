FactoryBot.define do
  factory :order do
    association :user
    association :shop

    status { :created }
    sequence(:order_number) { |n| n }
    total_price { 1500 }
    customer_comment { nil }
    inventory_restored_at { nil }
    checkout_idempotency_key { nil }

    after(:build) do |order|
      next unless order.shop

      snapshots = OrderSnapshots::Build.new(shop: order.shop).call
      order.shop_snapshot = snapshots[:shop_snapshot]
      order.legal_profile_snapshot = snapshots[:legal_profile_snapshot]
      order.customer_snapshot = {
        "full_name" => order.user.full_name,
        "phone" => order.user.phone_display,
        "email" => order.user.email
      } if order.customer_snapshot.blank?
    end
  end
end
