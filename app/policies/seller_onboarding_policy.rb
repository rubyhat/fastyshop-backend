# frozen_string_literal: true

class SellerOnboardingPolicy < ApplicationPolicy
  def create?
    user.present?
  end
end
