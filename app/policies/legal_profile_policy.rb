class LegalProfilePolicy < ApplicationPolicy
  def index?
    user.present? && (user.superadmin? || user.supermanager? || user.seller_profile.present?)
  end

  def show?
    user.present? && (user.superadmin? || user.supermanager? || owns_record_seller_profile?)
  end

  def create?
    user.present? && owns_record_seller_profile?
  end

  def update?
    user.present? && (user.superadmin? || user.supermanager? || owns_record_seller_profile?)
  end

  def submit_verification?
    user.present? && owns_record_seller_profile?
  end

  def approve?
    user.present? && (user.superadmin? || user.supermanager?)
  end

  def reject?
    user.present? && (user.superadmin? || user.supermanager?)
  end

  def verification_events?
    user.present? && (user.superadmin? || user.supermanager? || owns_record_seller_profile?)
  end


  class Scope < Scope
    def resolve
      return scope.none unless user.present?

      if user.superadmin? || user.supermanager?
        scope.all
      else
        profile_ids = user.seller_profile&.legal_profiles&.pluck(:id) || []
        scope.where(id: profile_ids)
      end
    end
  end

  private

  def owns_record_seller_profile?
    user&.seller_profile.present? && record.seller_profile_id == user.seller_profile.id
  end
end
