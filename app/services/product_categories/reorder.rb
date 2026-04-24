# frozen_string_literal: true

module ProductCategories
  class Reorder
    Result = Struct.new(:categories, :error_record, keyword_init: true) do
      def success?
        error_record.nil?
      end
    end

    # @param shop [Shop]
    # @param positions [Array<Hash>]
    def initialize(shop:, positions:)
      @shop = shop
      @positions = Array(positions)
    end

    # @return [Result]
    def call
      updated_categories = []

      ActiveRecord::Base.transaction do
        positions.each do |item|
          category = shop.product_categories.find(item[:id] || item["id"])
          category.update!(position: item[:position] || item["position"])
          updated_categories << category
        end
      end

      Result.new(categories: updated_categories)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(categories: updated_categories, error_record: e.record)
    rescue ActiveRecord::RecordNotFound
      record = ProductCategory.new(shop: shop)
      record.errors.add(:base, "Одна или несколько категорий не найдены")
      Result.new(categories: updated_categories, error_record: record)
    end

    private

    attr_reader :shop, :positions
  end
end
