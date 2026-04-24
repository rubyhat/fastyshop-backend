# frozen_string_literal: true

class ShopChangeEvent < ApplicationRecord
  belongs_to :shop
  belongs_to :actor_user, class_name: "User", optional: true

  enum :event_type, {
    created: 0,
    title_changed: 1,
    slug_changed: 2,
    contacts_changed: 3,
    legal_profile_changed: 4,
    status_changed: 5
  }

  validates :event_type, presence: true
  validates :changeset, presence: true

  # @return [String]
  def public_summary
    case event_type
    when "created"
      "Магазин создан"
    when "title_changed"
      "Изменено название магазина"
    when "slug_changed"
      "Изменён публичный адрес магазина"
    when "contacts_changed"
      "Изменены контактные данные магазина"
    when "legal_profile_changed"
      "Магазин был привязан к другому юридическому профилю"
    when "status_changed"
      status_summary
    else
      "Изменены данные магазина"
    end
  end

  # @return [Hash]
  def public_changes
    changeset.slice("from", "to", "fields")
  end

  private

  def status_summary
    case changeset["to"]
    when "disabled_by_owner"
      "Магазин был временно отключён владельцем"
    when "suspended_by_admin"
      "Магазин был временно отключён платформой"
    when "active"
      "Магазин снова активен"
    else
      "Изменён статус магазина"
    end
  end
end
