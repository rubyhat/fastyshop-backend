FactoryBot.define do
  factory :legal_profile_verification_event do
    association :legal_profile
    association :actor_user, factory: :user
    event_type { :submitted }
    from_status { "draft" }
    to_status { "pending_review" }
    comment { nil }
    metadata { {} }
  end
end
