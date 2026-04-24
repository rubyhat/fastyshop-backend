
class SellerProfilePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && (user.superadmin? || user.supermanager? || user.id == record.user_id)
  end

  def create?
    user.present?
  end

  def update?
    user.present? && (user.superadmin? || user.supermanager? || user.id == record.user_id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.present?

      if user.superadmin? || user.supermanager?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
