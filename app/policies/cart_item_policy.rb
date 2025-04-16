# frozen_string_literal: true

# Политика доступа для CartItem — через принадлежность к Cart
class CartItemPolicy < ApplicationPolicy
  # Добавление товара в корзину
  def create?
    user.present? && record.cart.user_id == user.id
  end

  # Просмотр отдельного элемента (возможно пригодится в будущем)
  def show?
    user.present? && record.cart.user_id == user.id
  end

  # Удаление из корзины
  def destroy?
    user.present? && record.cart.user_id == user.id
  end

  def update?
    false
  end

  class Scope < Scope
    def resolve
      scope.joins(:cart).where(carts: { user_id: user.id })
    end
  end
end
