# frozen_string_literal: true

module OrderSnapshots
  # Build creates immutable trust snapshots for an order at checkout time.
  class Build
    # @param shop [Shop]
    def initialize(shop:)
      @shop = shop
    end

    # @return [Hash]
    def call
      {
        shop_snapshot: shop_snapshot,
        legal_profile_snapshot: legal_profile_snapshot
      }
    end

    private

    attr_reader :shop

    def legal_profile
      @legal_profile ||= shop.legal_profile
    end

    def shop_snapshot
      {
        id: shop.id,
        title: shop.title,
        slug: shop.slug,
        contact_phone: shop.contact_phone,
        contact_email: shop.contact_email,
        physical_address_public: shop.physical_address_public,
        shop_type: shop.shop_type,
        status: shop.status,
        verified_badge: shop.verified_badge,
        seller_profile_id: shop.seller_profile_id,
        legal_profile_id: shop.legal_profile_id,
        shop_category_id: shop.shop_category_id
      }
    end

    def legal_profile_snapshot
      {
        id: legal_profile.id,
        country_code: legal_profile.country_code,
        legal_name: legal_profile.legal_name,
        legal_form_code: legal_profile.legal_form_code,
        legal_form_label: legal_profile.legal_form_label,
        registration_number_type: legal_profile.registration_number_type,
        registration_number_public: legal_profile.registration_number_public,
        legal_address_public: legal_profile.legal_address_public,
        verification_status: legal_profile.verification_status
      }
    end
  end
end
