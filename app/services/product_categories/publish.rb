# frozen_string_literal: true

module ProductCategories
  class Publish
    Result = Struct.new(:category, :error_record, keyword_init: true) do
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
      if category.parent.present? && !category.parent.published?
        category.errors.add(:parent_id, "родительская категория должна быть опубликована")
        return Result.new(category: category, error_record: category)
      end

      category.status = :published
      category.published_at = Time.current
      category.published_by = actor_user
      category.archived_at = nil
      category.archived_by = nil
      category.save!
      category.record_lifecycle_event!(event_type: :published, actor_user: actor_user)

      Result.new(category: category)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(category: category, error_record: e.record)
    end

    private

    attr_reader :category, :actor_user
  end
end
