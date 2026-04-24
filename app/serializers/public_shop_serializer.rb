# frozen_string_literal: true

class PublicShopSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :slug,
             :canonical_slug,
             :canonical_path,
             :redirect_required,
             :description,
             :logo_url,
             :contact_phone,
             :contact_email,
             :physical_address_public,
             :shop_type,
             :status,
             :verified_badge,
             :public_alert,
             :content_state,
             :seller,
             :trust_summary

  # @return [String]
  def canonical_slug
    object.slug
  end

  # @return [Boolean]
  def redirect_required
    requested_slug.present? && requested_slug != object.slug
  end

  # @return [String, nil]
  def description
    object.storefront_content_visible? ? object.description : nil
  end

  # @return [Hash]
  def seller
    {
      display_name: object.seller_profile.display_name,
      slug: object.seller_profile.slug,
      logo_url: object.seller_profile.logo_url
    }
  end

  # @return [Hash]
  def trust_summary
    {
      verification_status: object.legal_profile.verification_status,
      legal_form_label: object.legal_profile.legal_form_label,
      registration_number_public: object.legal_profile.registration_number_public,
      legal_details_path: "/api/v1/public/shops/#{object.slug}/legal_details",
      change_history_path: "/api/v1/public/shops/#{object.slug}/change_history"
    }
  end

  private

  def requested_slug
    instance_options[:requested_slug].to_s.presence
  end
end
