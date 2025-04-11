# frozen_string_literal: true

# Политика доступа к категориям товаров/услуг магазина.
#
# Позволяет управлять категориями только владельцу магазина и администраторам.
#
class ProductCategoryPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    owner_or_admin?
  end

  def update?
    owner_or_admin?
  end

  def destroy?
    owner_or_admin?
  end

  class Scope < Scope
    # Показываем только активные категории
    def resolve
      scope.where(is_active: true)
    end
  end

  private

  def owner_or_admin?
    user&.superadmin? || user&.supermanager? || record.shop.seller_profile.user_id == user.id
  end
end
