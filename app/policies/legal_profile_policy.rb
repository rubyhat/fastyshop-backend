class LegalProfilePolicy < ApplicationPolicy
  def index?
    !user.superadmin? || user.supermanager? || owns_seller_profile?
  end

  def show?
    true
  end

  def create?
      user.present? && owns_seller_profile?
  end

  def update?
    user.superadmin? || user.supermanager? || owns_seller_profile?
  end

  def unverify?
    user.present? && owns_seller_profile? && record.is_verified
  end


  class Scope < Scope
    def resolve
      if user.superadmin? || user.supermanager?
        scope.all
      else
        # scope.joins(:seller_profile).where(seller_profiles: { user_id: user.id })
        profile_ids = user.seller_profile&.legal_profiles&.pluck(:id) || []
        scope.where(id: profile_ids)
      end
    end
  end

  private

  def owns_seller_profile?
    record.respond_to?(:seller_profile) &&
      record.seller_profile&.user_id == user.id
  end
end
