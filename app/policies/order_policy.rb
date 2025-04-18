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
    user.present? && record.shop.seller_profile.user_id == user.id
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
