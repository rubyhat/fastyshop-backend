class ShopCategoryPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def index?
      true
    end

    def show?
      true
    end

    def create?
      user.superadmin? || user.supermanager?
    end

    def update?
      user.superadmin? || user.supermanager?
    end

    def destroy?
      user.superadmin? || user.supermanager?
    end
  end
end
