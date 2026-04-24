# frozen_string_literal: true

module Shops
  # Create centralizes shop creation and records the initial trust event.
  class Create
    Result = Struct.new(:shop, :error_record, keyword_init: true) do
      def success?
        error_record.nil?
      end
    end

    # @param seller_profile [SellerProfile]
    # @param actor_user [User, nil]
    # @param attributes [Hash, ActionController::Parameters]
    def initialize(seller_profile:, actor_user:, attributes:)
      @seller_profile = seller_profile
      @actor_user = actor_user
      @attributes = attributes.to_h.deep_symbolize_keys
    end

    # @return [Result]
    def call
      shop = seller_profile.shops.build(attributes)

      ActiveRecord::Base.transaction do
        shop.save!
        record_created_event!(shop)
      end

      Result.new(shop: shop)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(shop: shop, error_record: e.record)
    end

    private

    attr_reader :seller_profile, :actor_user, :attributes

    def record_created_event!(shop)
      shop.change_events.create!(
        event_type: :created,
        actor_user: actor_user,
        changeset: {
          to: {
            title: shop.title,
            slug: shop.slug,
            legal_profile_id: shop.legal_profile_id,
            status: shop.status
          }
        }
      )
    end
  end
end
