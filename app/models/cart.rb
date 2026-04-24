# frozen_string_literal: true

class Cart < ApplicationRecord
  belongs_to :shop
  belongs_to :user
  has_many :cart_items, dependent: :destroy

  enum :status, {
    active: 0,
    converted: 1,
    expired: 2,
    abandoned: 3
  }, default: :active

  before_validation :assign_expired_at, on: :create

  validates :user_id, :shop_id, :expired_at, :status, presence: true
  validates :shop_id,
            uniqueness: {
              scope: :user_id,
              conditions: -> { where(status: :active) },
              message: "Уже есть активная корзина для этого магазина"
            },
            if: :active?

  validate :cannot_add_self_shop

  scope :active_state, -> { where(status: :active) }

  # @return [Integer]
  def items_count
    cart_items.sum(:quantity)
  end

  # @return [Boolean]
  def empty?
    cart_items.none?
  end

  # @return [void]
  def mark_converted!
    update!(status: :converted, converted_at: Time.current)
  end

  private

  def cannot_add_self_shop
    return unless user && shop && shop.seller_profile.user_id == user.id

    errors.add(:base, "Вы не можете добавить товары из собственного магазина")
  end

  def assign_expired_at
    self.expired_at ||= 30.days.from_now
  end
end
