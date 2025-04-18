# frozen_string_literal: true

# Сериализатор для позиции в корзине
#
# @return [UUID] id — UUID записи
# @return [UUID] product_id — ID товара
# @return [Integer] quantity — Количество
# @return [Decimal] price_snapshot — Цена на момент добавления
class CartItemSerializer < ActiveModel::Serializer
  attributes :id, :product_id, :quantity, :price_snapshot
end
