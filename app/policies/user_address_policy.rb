# frozen_string_literal: true

class UserAddressPolicy < ApplicationPolicy
  def index?
    owner_or_admin?
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

  class Scope < Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end

  def owner_or_admin?
    return false unless user
    return true if user.superadmin? || user.supermanager?

    # Защищает от вызова .user_id на классе
    record.respond_to?(:user_id) && record.user_id == user.id
  end
end
