# frozen_string_literal: true

module SellerProfiles
  # Create creates seller profile and upgrades the user role to seller in one transaction.
  class Create
    # @param user [User]
    # @param attributes [Hash, ActionController::Parameters]
    def initialize(user:, attributes:)
      @user = user
      @attributes = attributes.to_h.deep_symbolize_keys
    end

    # @return [SellerProfile]
    def call
      profile = user.build_seller_profile(attributes)

      ActiveRecord::Base.transaction do
        profile.save!
        user.update!(role: :seller)
      end

      profile
    rescue ActiveRecord::RecordInvalid => e
      return profile if e.record == profile

      profile.errors.add(:base, e.record.errors.full_messages.to_sentence.presence || "Не удалось перевести пользователя в статус продавца")
      profile
    end

    private

    attr_reader :user, :attributes
  end
end
