
class SellerProfilePolicy < ApplicationPolicy
  def index?
    user.superadmin? || user.supermanager?
  end

  def show?
    true
  end

  def create?
    user.present? && user.seller_profile.blank?
  end

  def update?
    user.superadmin? || user.supermanager? || user.id == record.user_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.superadmin? || user.supermanager?
        scope.all
      else
        scope.none
      end
    end
  end
end
