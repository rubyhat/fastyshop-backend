# frozen_string_literal: true

# Политика доступа для модели Cart
class CartPolicy < ApplicationPolicy
  # Пользователь может видеть только свои корзины
  def index?
    user.present?
  end

  def show?
    user.present? && record.user_id == user.id
  end

  # Пользователь может создавать корзину только для себя
  def create?
    user.present?
  end

  # Пользователь может удалять товары из своей корзины
  def destroy?
    user.present? && record.user_id == user.id
  end

  # Не позволяем обновлять корзину напрямую (только через add/remove)
  def update?
    false
  end

  # Scope: только корзины текущего пользователя
  class Scope < Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end
end
