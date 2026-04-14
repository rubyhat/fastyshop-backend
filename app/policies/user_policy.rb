class UserPolicy < ApplicationPolicy
  def me?
    user.superadmin? || user.id == record.id
  end

  def create?
    user.superadmin? || user.supermanager?
  end

  def update?
    user.superadmin? || user.supermanager? || user.id == record.id
  end

  def update_account_status?
    user.superadmin? || user.supermanager?
  end

  def permitted_update_params
    if user.superadmin? || user.supermanager?
      %i[email password password_confirmation first_name last_name middle_name]
    elsif user.id == record.id
      %i[email password password_confirmation first_name last_name middle_name]
    else
      []
    end
  end

  def manage_seller_profile?
    user.superadmin? || user.supermanager? || user.id == record.user_id
  end

  def show?
    user.superadmin? || user.supermanager? || user.id == record.id
  end

  def destroy?
    user.superadmin? || user.supermanager? || user.id == record.id
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end
end
