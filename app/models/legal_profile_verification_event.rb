# frozen_string_literal: true

class LegalProfileVerificationEvent < ApplicationRecord
  belongs_to :legal_profile
  belongs_to :actor_user, class_name: "User", optional: true

  enum :event_type, {
    submitted: 0,
    approved: 1,
    rejected: 2,
    reset_to_draft: 3
  }

  validates :event_type, presence: true
end
