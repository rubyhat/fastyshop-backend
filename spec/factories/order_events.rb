FactoryBot.define do
  factory :order_event do
    association :order
    actor_user { order.user }
    event_type { "created" }
    from_status { nil }
    to_status { order.status }
    comment { nil }
    metadata { {} }
  end
end
