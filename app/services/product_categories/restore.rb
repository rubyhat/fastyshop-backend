# frozen_string_literal: true

module ProductCategories
  class Restore
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
      category.status = :draft
      category.published_at = nil
      category.published_by = nil
      category.archived_at = nil
      category.archived_by = nil
      category.save!
      category.record_lifecycle_event!(event_type: :restored, actor_user: actor_user)

      Result.new(category: category)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(category: category, error_record: e.record)
    end

    private

    attr_reader :category, :actor_user
  end
end
