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
  validates :shop_id, uniqueness: { scope: :user_id }

  # Scope: только активные корзины (не просроченные)
  scope :active, -> { where("expired_at > ?", Time.current) }
end
