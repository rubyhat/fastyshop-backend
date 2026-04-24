# frozen_string_literal: true

# Политика доступа для модели Cart
class CartPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && record.user_id == user.id
  end

  def add_item?
    user.present? && record.user_id == user.id
  end

  def remove_item?
    user.present? && record.user_id == user.id
  end

  def update?
    false
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.where(user_id: user.id)
    end
  end
end
