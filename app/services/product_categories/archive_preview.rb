# frozen_string_literal: true

module ProductCategories
  class ArchivePreview
    # @param category [ProductCategory]
    def initialize(category:)
      @category = category
    end

    # @return [Hash]
    def call
      category_ids = affected_category_ids
      products = Product.where(shop_id: category.shop_id, product_category_id: category_ids)

      {
        category: {
          id: category.id,
          title: category.title
        },
        affected: {
          child_categories_count: category_ids.size - 1,
          products_count: products.count
        },
        sample: {
          categories: ProductCategory.where(id: category_ids.drop(1)).limit(10).map { |record| short_category(record) },
          products: products.limit(10).map { |record| short_product(record) }
        }
      }
    end

    # @return [Array<String>]
    def affected_category_ids
      [ category.id ] + category.descendant_ids
    end

    private

    attr_reader :category

    def short_category(record)
      {
        id: record.id,
        title: record.title
      }
    end

    def short_product(record)
      {
        id: record.id,
        title: record.title
      }
    end
  end
end
