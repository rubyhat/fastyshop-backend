# frozen_string_literal: true

class ShopPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    admin? || owns_shop?
  end

  def create?
    user.present? && (user.seller? || admin?)
  end

  def update?
    admin? || owns_shop?
  end

  def destroy?
    update?
  end

  def disable?
    update?
  end

  def activate?
    return false unless update?
    return admin? if record.suspended_by_admin?

    true
  end

  def suspend?
    admin?
  end

  def manage_orders?
    admin? || owns_shop?
  end

  class Scope < Scope
    def resolve_catalog
      scope.active
    end

    def resolve_owner_view
      if user&.admin?
        scope.all
      elsif user&.seller_profile
        scope.where(seller_profile_id: user.seller_profile.id)
      else
        scope.none
      end
    end
  end

  private

  def admin?
    user&.admin?
  end

  def owns_shop?
    return false unless user && record.respond_to?(:seller_profile)

    record.seller_profile&.user_id == user.id
  end
end
