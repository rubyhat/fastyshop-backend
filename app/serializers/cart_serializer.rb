# frozen_string_literal: true

# Сериализатор для корзины
#
# @return [UUID] id — UUID корзины
# @return [UUID] user_id — ID пользователя
# @return [UUID] shop_id — ID магазина
# @return [DateTime] expired_at — Срок действия корзины
class CartSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :shop_id, :expired_at

  has_many :cart_items, serializer: CartItemSerializer
end
