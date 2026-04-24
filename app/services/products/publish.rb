# frozen_string_literal: true

module Products
  class Publish
    Result = Struct.new(:product, :error_record, keyword_init: true) do
      def success?
        error_record.nil?
      end
    end

    # @param product [Product]
    # @param actor_user [User]
    def initialize(product:, actor_user:)
      @product = product
      @actor_user = actor_user
    end

    # @return [Result]
    def call
      validate_publish_requirements
      return Result.new(product: product, error_record: product) if product.errors.any?

      product.status = :published
      product.published_at = Time.current
      product.published_by = actor_user
      product.archived_at = nil
      product.archived_by = nil
      product.save!
      product.record_lifecycle_event!(event_type: :published, actor_user: actor_user)

      Result.new(product: product)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(product: product, error_record: e.record)
    end

    private

    attr_reader :product, :actor_user

    def validate_publish_requirements
      product.errors.add(:price, "должна быть указана перед публикацией") if product.price.blank?

      if product.product_category.present? && !product.product_category.published?
        product.errors.add(:product_category_id, "категория должна быть опубликована перед публикацией товара")
      end

      return unless product.physical?

      if product.stock_quantity.nil?
        product.errors.add(:stock_quantity, "должен быть указан для физического товара")
      end
    end
  end
end
