# frozen_string_literal: true

# Модель корзины пользователя в конкретном магазине
#
# @!attribute id
#   @return [UUID] Уникальный идентификатор корзины
# @!attribute user_id
#   @return [UUID] Пользователь, владелец корзины
# @!attribute shop_id
#   @return [UUID] Магазин, к которому относится корзина
# @!attribute expired_at
#   @return [DateTime] Время, когда корзина считается устаревшей
#
class Cart < ApplicationRecord
  belongs_to :shop
  belongs_to :user
  has_many :cart_items, dependent: :destroy

  validates :user_id, :shop_id, :expired_at, presence: true
  validates :shop_id, uniqueness: { scope: :user_id, message: "Уже есть активная корзина для этого магазина" }

  validate :cannot_add_self_shop

  # Scope: только активные корзины (не просроченные)
  scope :active, -> { where("expired_at > ?", Time.current) }

  private

  # Нельзя создать корзину на собственный магазин
  def cannot_add_self_shop
    return unless user && shop && shop.seller_profile.user_id == user.id

    errors.add(:base, "Вы не можете добавить товары из собственного магазина")
  end
end
