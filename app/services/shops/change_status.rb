# frozen_string_literal: true

module Shops
  # ChangeStatus centralizes shop lifecycle transitions.
  class ChangeStatus
    Result = Struct.new(:shop, :error_record, keyword_init: true) do
      def success?
        error_record.nil?
      end
    end

    # @param shop [Shop]
    # @param actor_user [User]
    # @param target_status [String, Symbol]
    # @param comment [String, nil]
    def initialize(shop:, actor_user:, target_status:, comment: nil)
      @shop = shop
      @actor_user = actor_user
      @target_status = target_status.to_s
      @comment = comment.to_s.presence
    end

    # @return [Result]
    def call
      return invalid_status_result unless Shop.statuses.key?(target_status)
      return owner_cannot_restore_admin_suspension_result if owner_cannot_restore_admin_suspension?
      return comment_required_result if target_status == "suspended_by_admin" && comment.blank?

      ActiveRecord::Base.transaction do
        previous_status = shop.status
        shop.status = target_status
        shop.status_comment = status_comment_for_target
        shop.save!
        record_status_change!(previous_status)
      end

      Result.new(shop: shop)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(shop: shop, error_record: e.record)
    end

    private

    attr_reader :shop, :actor_user, :target_status, :comment

    def owner_cannot_restore_admin_suspension?
      shop.suspended_by_admin? && target_status == "active" && !actor_user&.admin?
    end

    def invalid_status_result
      shop.errors.add(:status, "Недопустимый статус магазина")
      Result.new(shop: shop, error_record: shop)
    end

    def owner_cannot_restore_admin_suspension_result
      shop.errors.add(:status, "Только администратор может вернуть магазин после отключения платформой")
      Result.new(shop: shop, error_record: shop)
    end

    def comment_required_result
      shop.errors.add(:status_comment, "Укажите причину отключения магазина")
      Result.new(shop: shop, error_record: shop)
    end

    def status_comment_for_target
      target_status == "suspended_by_admin" ? comment : nil
    end

    def record_status_change!(previous_status)
      return if previous_status == shop.status

      shop.change_events.create!(
        event_type: :status_changed,
        actor_user: actor_user,
        changeset: {
          from: previous_status,
          to: shop.status
        }
      )
    end
  end
end
