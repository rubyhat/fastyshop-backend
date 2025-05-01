class UserPolicy < ApplicationPolicy
  def me?
    user.superadmin? || user.id == record.id
  end

  def create?
    true
  end

  def update?
    user.superadmin? || user.supermanager? || user.id == record.id
  end

  def permitted_update_params
    if user.superadmin? || user.supermanager?
      %i[phone email password password_confirmation country_code role is_active]
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
    true
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
