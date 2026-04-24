# frozen_string_literal: true

class OrderEvent < ApplicationRecord
  belongs_to :order
  belongs_to :actor_user, class_name: "User", optional: true

  enum :event_type, {
    created: 0,
    accepted: 1,
    rejected_by_seller: 2,
    canceled_by_user: 3,
    canceled_by_seller: 4,
    moved_to_in_progress: 5,
    marked_ready: 6,
    completed: 7,
    comment_added: 8
  }

  validates :event_type, :to_status, presence: true

  scope :public_commentable, -> { where(event_type: %i[rejected_by_seller canceled_by_user canceled_by_seller]).where.not(comment: [ nil, "" ]) }
end
