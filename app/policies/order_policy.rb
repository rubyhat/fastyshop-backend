# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false unless user
    return true if user.admin?

    record.user_id == user.id || record.shop.seller_profile.user_id == user.id
  end

  def create_from_cart?
    user.present?
  end

  def my_orders?
    user.present?
  end

  def shop_orders?
    user.present? && record.seller_profile.user_id == user.id
  end

  def update_status?
    return false unless user
    return true if user.admin?
    return true if record.shop.seller_profile.user_id == user.id
    return true if record.user_id == user.id
    false
  end

  def events?
    show?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.admin?
        scope.all
      elsif user.seller_profile
        scope.where(shop_id: user.seller_profile.shops.select(:id))
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
