# frozen_string_literal: true

module SellerOnboarding
  # Create handles the first seller onboarding flow in one DB transaction.
  class Create
    Result = Struct.new(:seller_profile, :legal_profile, :shop, :error_record, keyword_init: true) do
      def success?
        error_record.nil?
      end
    end

    # @param user [User]
    # @param seller_profile_attributes [Hash, ActionController::Parameters]
    # @param legal_profile_attributes [Hash, ActionController::Parameters]
    # @param shop_attributes [Hash, ActionController::Parameters]
    def initialize(user:, seller_profile_attributes:, legal_profile_attributes:, shop_attributes:)
      @user = user
      @seller_profile_attributes = seller_profile_attributes.to_h.deep_symbolize_keys
      @legal_profile_attributes = legal_profile_attributes.to_h.deep_symbolize_keys
      @shop_attributes = shop_attributes.to_h.deep_symbolize_keys
    end

    # @return [Result]
    def call
      if user.seller_profile.present?
        seller_profile = user.seller_profile
        seller_profile.errors.add(:base, "Профиль продавца уже существует")
        return Result.new(error_record: seller_profile)
      end

      result = nil

      ActiveRecord::Base.transaction do
        seller_profile = SellerProfiles::Create.new(
          user: user,
          attributes: seller_profile_attributes
        ).call
        unless seller_profile.persisted?
          result = Result.new(error_record: seller_profile)
          raise ActiveRecord::Rollback
        end

        legal_profile = seller_profile.legal_profiles.build(legal_profile_attributes)
        legal_profile.save!

        shop_result = Shops::Create.new(
          seller_profile: seller_profile,
          actor_user: user,
          attributes: shop_attributes.merge(legal_profile_id: legal_profile.id)
        ).call
        unless shop_result.success?
          result = Result.new(error_record: shop_result.error_record)
          raise ActiveRecord::Rollback
        end

        shop = shop_result.shop

        result = Result.new(
          seller_profile: seller_profile,
          legal_profile: legal_profile,
          shop: shop
        )
      rescue ActiveRecord::RecordInvalid => e
        result = Result.new(error_record: e.record)
        raise ActiveRecord::Rollback
      end

      result || Result.new(error_record: user)
    end

    private

    attr_reader :user, :seller_profile_attributes, :legal_profile_attributes, :shop_attributes
  end
end
