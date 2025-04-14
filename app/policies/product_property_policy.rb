# frozen_string_literal: true

class ProductPropertyPolicy < ApplicationPolicy
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

  class Scope < Scope
    def resolve
      scope.where("source_type = ? OR user_id = ?", ProductProperty.source_types[:global], user&.id)
    end
  end

  private

  def owner_or_admin?
    return false unless user

    user.superadmin? ||
      user.supermanager? ||
      user.seller? && record.user_id == user.id
  end
end
