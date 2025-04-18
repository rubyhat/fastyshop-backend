# frozen_string_literal: true

class CartItem < ApplicationRecord
  belongs_to :product
  belongs_to :cart

  validates :cart_id, :product_id, :quantity, :price_snapshot, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :product_id, uniqueness: { scope: :cart_id }

  validate :product_belongs_to_same_shop
  validate :not_exceed_stock_quantity, if: -> { product.present? && quantity.present? }

  private

  # Продукт должен принадлежать тому же магазину, что и корзина
  def product_belongs_to_same_shop
    return unless cart && product

    if cart.shop_id != product.shop_id
      errors.add(:product_id, "Товар не принадлежит магазину корзины")
    end
  end

  # Нельзя добавить в корзину больше, чем есть в наличии
  def not_exceed_stock_quantity
    # Найти уже существующую запись в корзине, если мы редактируем/обновляем
    existing_item = CartItem.where(cart_id: cart_id, product_id: product_id).where.not(id: id).first
    total_quantity = quantity
    total_quantity += existing_item.quantity if existing_item.present?

    if total_quantity > product.stock_quantity
      errors.add(:quantity, "Недостаточно товара на складе. Доступно: #{product.stock_quantity}")
    end
  end
end
