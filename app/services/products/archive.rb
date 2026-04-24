# frozen_string_literal: true

module Products
  class Archive
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
      return Result.new(product: product) if product.archived?

      product.status = :archived
      product.archived_at = Time.current
      product.archived_by = actor_user
      product.save!
      product.record_lifecycle_event!(event_type: :archived, actor_user: actor_user)

      Result.new(product: product)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(product: product, error_record: e.record)
    end

    private

    attr_reader :product, :actor_user
  end
end
