FactoryBot.define do
  factory :shop_change_event do
    association :shop
    event_type { :title_changed }
    changeset { { from: "Old title", to: "New title" } }
  end
end
