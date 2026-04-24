# frozen_string_literal: true

class PublicShopCatalogSerializer < ActiveModel::Serializer
  attributes :title,
             :slug,
             :logo_url,
             :shop_type,
             :verified_badge,
             :shop_category,
             :trust_summary

  # @return [Hash]
  def shop_category
    {
      name: object.shop_category.name,
      title: object.shop_category.title
    }
  end

  # @return [Hash]
  def trust_summary
    {
      verification_status: object.legal_profile.verification_status,
      legal_form_label: object.legal_profile.legal_form_label
    }
  end
end
