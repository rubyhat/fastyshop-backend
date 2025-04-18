# frozen_string_literal: true

# Модель элемента в корзине
#
# @!attribute id
#   @return [UUID] Уникальный идентификатор позиции
# @!attribute cart_id
#   @return [UUID] Ссылка на корзину
# @!attribute product_id
#   @return [UUID] Ссылка на товар
# @!attribute quantity
#   @return [Integer] Количество
# @!attribute price_snapshot
#   @return [Decimal] Цена на момент добавления
#
class CartItem < ApplicationRecord
  belongs_to :product
  belongs_to :cart


  validates :cart_id, :product_id, :quantity, :price_snapshot, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :product_id, uniqueness: { scope: :cart_id }

  validate :product_belongs_to_same_shop

  private

  # Продукт должен принадлежать тому же магазину, что и корзина
  def product_belongs_to_same_shop
    return unless cart && product
    if cart.shop_id != product.shop_id
      errors.add(:product_id, "Товар не принадлежит магазину корзины")
    end
  end
end
