# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :user
  belongs_to :shop
  has_many :order_items, dependent: :destroy

  enum :status, {
    created: 0,
    accepted: 1,
    delivery_in_progress: 2,
    ready_for_pickup: 3,
    completed: 4,
    canceled_by_user: 5,
    canceled_by_seller: 6
  }, suffix: true

  enum :delivery_method, {
    courier: 0,
    postal_service: 1,
    pickup: 2
  }

  enum :payment_method, {
    cash_on_delivery: 0,
    card_on_delivery: 1,
    online: 2,
    cash_on_pickup: 3
  }

  validates :status, :delivery_method, :payment_method, :total_price,
            :contact_name, :contact_phone, :delivery_address_text,
            presence: true

  validates :total_price, numericality: { greater_than_or_equal_to: 0 }
end
