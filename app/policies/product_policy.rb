# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.is_active? || owner_or_admin?
  end

  def create?
    user.present? && (user.seller? || user.superadmin? || user.supermanager?)
  end

  def update?
    owner_or_admin?
  end

  def destroy?
    owner_or_admin?
  end

  class Scope < Scope
    def resolve
      if user&.superadmin? || user&.supermanager?
        scope.all
      elsif user&.seller_profile
        scope.where(shop_id: user.seller_profile.shops.select(:id))
      else
        scope.where(is_active: true)
      end
    end
  end

  private

  def owner_or_admin?
    return false unless user && record.shop

    user.superadmin? ||
      user.supermanager? ||
      record.shop.seller_profile&.user_id == user.id
  end
end
