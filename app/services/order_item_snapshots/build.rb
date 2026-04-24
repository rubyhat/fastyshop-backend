# frozen_string_literal: true

module OrderItemSnapshots
  # Build creates immutable product data for an order item at checkout time.
  class Build
    # @param product [Product]
    def initialize(product:)
      @product = product
    end

    # @return [Hash]
    def call
      {
        product_id: product.id,
        title: product.title,
        slug: product.slug,
        product_type: product.product_type,
        price: product.price.to_s,
        category_id: product.product_category_id,
        category_title: product.product_category&.title,
        sku: product.sku,
        status: product.status
      }
    end

    private

    attr_reader :product
  end
end
