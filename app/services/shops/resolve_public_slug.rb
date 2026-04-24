# frozen_string_literal: true

module Shops
  # ResolvePublicSlug resolves both canonical and historical shop slugs.
  class ResolvePublicSlug
    Result = Struct.new(:shop, :requested_slug, :historical, keyword_init: true) do
      def found?
        shop.present?
      end

      def redirect_required?
        historical && shop.present? && requested_slug != shop.slug
      end
    end

    # @param slug [String]
    def initialize(slug:)
      @slug = slug.to_s.strip.downcase
    end

    # @return [Result]
    def call
      shop = Shop.includes(:seller_profile, :legal_profile, :shop_category).find_by(slug: slug)
      return Result.new(shop: shop, requested_slug: slug, historical: false) if shop

      history = ShopSlugHistory.includes(shop: %i[seller_profile legal_profile shop_category]).find_by(slug: slug)
      Result.new(shop: history&.shop, requested_slug: slug, historical: history.present?)
    end

    private

    attr_reader :slug
  end
end
