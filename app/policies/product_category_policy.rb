# frozen_string_literal: true

class ProductCategoryPolicy < ApplicationPolicy
  def index?
    user.present?
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
    archive?
  end

  def publish?
    owner_or_admin?
  end

  def archive_preview?
    owner_or_admin?
  end

  def archive?
    owner_or_admin?
  end

  def restore?
    owner_or_admin?
  end

  def reorder?
    owner_or_admin?
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user&.seller_profile
        scope.where(shop_id: user.seller_profile.shops.select(:id))
      else
        scope.none
      end
    end
  end

  private

  def owner_or_admin?
    return false unless user && record.respond_to?(:shop) && record.shop

    user.admin? || record.shop.seller_profile.user_id == user.id
  end
end
