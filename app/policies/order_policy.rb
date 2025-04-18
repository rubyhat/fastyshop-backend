# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  def create_from_cart?
    user.present? || user.superadmin? || user.supermanager?
  end

  def my_orders?
    user.present?
  end

  def shop_orders?
    user.present? && record.seller_profile.user_id == user.id
  end

  def update_status?
    return false unless user
    return true if user.superadmin? || user.supermanager?
    return true if record.shop.seller_profile.user_id == user.id
    return true if record.user_id == user.id && record.status_created? # покупатель может отменить
    false
  end

  def cancel?
    record.user_id == user.id
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
