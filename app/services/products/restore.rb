# frozen_string_literal: true

module Products
  class Restore
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
      product.status = :draft
      product.published_at = nil
      product.published_by = nil
      product.archived_at = nil
      product.archived_by = nil
      product.save!
      product.record_lifecycle_event!(event_type: :restored, actor_user: actor_user)

      Result.new(product: product)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(product: product, error_record: e.record)
    end

    private

    attr_reader :product, :actor_user
  end
end
