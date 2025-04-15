# frozen_string_literal: true

class ProductPropertyValuePolicy < ApplicationPolicy
  def index?
    user.present? && (user.seller? || user.superadmin? || user.supermanager?)
  end

  def show?
    owner_or_admin?
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

  private

  def owner_or_admin?
    return false unless user && record.product

    user.superadmin? ||
      user.supermanager? ||
      user.seller? && record.product.shop.seller_profile&.user_id == user.id
  end
end
