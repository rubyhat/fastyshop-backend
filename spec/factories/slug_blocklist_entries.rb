FactoryBot.define do
  factory :slug_blocklist_entry do
    sequence(:term) { |n| "blocked-term-#{n}" }
    match_type { :exact }
    is_active { true }
  end
end
