# frozen_string_literal: true

class CatalogLifecycleEvent < ApplicationRecord
  belongs_to :record, polymorphic: true
  belongs_to :actor_user, class_name: "User", optional: true

  enum :event_type, {
    created: 0,
    published: 1,
    archived: 2,
    restored: 3
  }

  validates :record, :event_type, presence: true
end
