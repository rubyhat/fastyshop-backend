# frozen_string_literal: true

module ProductCategories
  class Archive
    Result = Struct.new(:category, :preview, :error_record, keyword_init: true) do
      def success?
        error_record.nil?
      end
    end

    # @param category [ProductCategory]
    # @param actor_user [User]
    def initialize(category:, actor_user:)
      @category = category
      @actor_user = actor_user
    end

    # @return [Result]
    def call
      preview = ArchivePreview.new(category: category).call
      category_ids = ArchivePreview.new(category: category).affected_category_ids
      now = Time.current

      ActiveRecord::Base.transaction do
        categories = ProductCategory.where(id: category_ids)
        products = Product.where(shop_id: category.shop_id, product_category_id: category_ids)

        categories.find_each do |record|
          archive_record!(record, now)
        end

        products.find_each do |record|
          archive_record!(record, now)
        end
      end

      Result.new(category: category.reload, preview: preview)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(category: category, preview: preview, error_record: e.record)
    end

    private

    attr_reader :category, :actor_user

    def archive_record!(record, timestamp)
      return if record.archived?

      record.update!(
        status: :archived,
        archived_at: timestamp,
        archived_by: actor_user
      )
      record.record_lifecycle_event!(event_type: :archived, actor_user: actor_user)
    end
  end
end
