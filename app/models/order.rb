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
  }, prefix: true

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


  validate :validate_status_transition, if: :status_transition_attempted?
  validate :validate_cancellation_rights, if: :status_changed_to_canceled_by_user?

  private

  # Проверка корректности перехода между статусами
  def validate_status_transition
    Rails.logger.info "Start validate_status_transition"
    return if new_record? # новый заказ — не проверяем

    valid_transitions = {
      created: %i[accepted canceled_by_user canceled_by_seller],
      accepted: %i[delivery_in_progress ready_for_pickup canceled_by_user canceled_by_seller],
      delivery_in_progress: %i[completed canceled_by_seller],
      ready_for_pickup: %i[completed canceled_by_seller],
      completed: [],
      canceled_by_user: [],
      canceled_by_seller: []
    }

    from = status_was.to_sym
    to = status.to_sym

    Rails.logger.info "Order status transition: #{from} → #{to}"

    unless valid_transitions[from].include?(to)
      errors.add(:base, "Нельзя изменить статус с #{from} на #{to}")
    end
  end

  # Проверка, что только пользователь может отменить заказ как canceled_by_user
  def validate_cancellation_rights
    return if Current.user.blank?
    return if user_id == Current.user.id
    return if Current.user.admin?

    errors.add(:base, "Вы не можете отменить заказ от имени покупателя")
  end

  # true, если статус становится canceled_by_user
  def status_changed_to_canceled_by_user?
    status_changed? && status_canceled_by_user?
  end

  def status_transition_attempted?
    Rails.logger.info "[ORDER] Проверка перехода статуса: #{status_was} → #{status}"
    status_changed? || status_was != status
  end
end
