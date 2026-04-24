# frozen_string_literal: true

module Orders
  class ChangeStatus
    ORDER_TRANSITIONS = {
      "created" => %w[accepted rejected_by_seller canceled_by_user],
      "accepted" => %w[in_progress ready canceled_by_seller],
      "in_progress" => %w[ready completed canceled_by_seller],
      "ready" => %w[completed canceled_by_seller],
      "completed" => [],
      "rejected_by_seller" => [],
      "canceled_by_user" => [],
      "canceled_by_seller" => []
    }.freeze

    COMMENT_REQUIRED_STATUSES = %w[rejected_by_seller canceled_by_user canceled_by_seller].freeze
    INVENTORY_RESTORE_STATUSES = %w[rejected_by_seller canceled_by_user canceled_by_seller].freeze

    EVENT_TYPE_MAP = {
      "accepted" => :accepted,
      "rejected_by_seller" => :rejected_by_seller,
      "canceled_by_user" => :canceled_by_user,
      "canceled_by_seller" => :canceled_by_seller,
      "in_progress" => :moved_to_in_progress,
      "ready" => :marked_ready,
      "completed" => :completed
    }.freeze

    Result = Struct.new(:order, :error_record, keyword_init: true) do
      def success?
        error_record.nil?
      end
    end

    # @param order [Order]
    # @param actor_user [User]
    # @param new_status [String, Symbol]
    # @param comment [String, nil]
    def initialize(order:, actor_user:, new_status:, comment:)
      @order = order
      @actor_user = actor_user
      @new_status = new_status.to_s
      @comment = comment.to_s.strip.presence
    end

    # @return [Result]
    def call
      return validation_error(:status, "Недопустимый статус") unless Order.statuses.key?(new_status)
      return Result.new(order: order) if new_status == order.status

      ActiveRecord::Base.transaction do
        order.lock!
        return validation_error(:base, "У вас нет прав на это изменение статуса") unless actor_allowed?
        return validation_error(:comment, "Комментарий обязателен для этого статуса") if comment_required? && comment.blank?
        return validation_error(:base, "Нельзя изменить статус с #{order.status} на #{new_status}") unless transition_allowed?

        from_status = order.status
        order.update!(status: new_status)
        restore_inventory_if_needed!
        order.record_event!(
          event_type: EVENT_TYPE_MAP.fetch(new_status),
          actor_user: actor_user,
          from_status: from_status,
          to_status: new_status,
          comment: buyer_visible_comment
        )
      end

      Result.new(order: order)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(order: order, error_record: e.record)
    end

    private

    attr_reader :order, :actor_user, :new_status, :comment

    def actor_allowed?
      return false unless actor_user
      return buyer_owns_order? if new_status == "canceled_by_user"

      seller_owns_shop? || actor_user.admin?
    end

    def transition_allowed?
      ORDER_TRANSITIONS.fetch(order.status, []).include?(new_status)
    end

    def comment_required?
      COMMENT_REQUIRED_STATUSES.include?(new_status)
    end

    def buyer_visible_comment
      COMMENT_REQUIRED_STATUSES.include?(new_status) ? comment : nil
    end

    def buyer_owns_order?
      order.user_id == actor_user.id && order.status_created?
    end

    def seller_owns_shop?
      order.shop.seller_profile.user_id == actor_user.id
    end

    def restore_inventory_if_needed!
      return unless INVENTORY_RESTORE_STATUSES.include?(new_status)
      return if order.inventory_restored_at.present?

      order.order_items.includes(:product).sort_by(&:product_id).each do |order_item|
        next unless order_item.product.physical?

        order_item.product.lock!
        order_item.product.increment!(:stock_quantity, order_item.quantity)
      end

      order.update!(inventory_restored_at: Time.current)
    end

    def validation_error(attribute, message)
      order.errors.add(attribute, message)
      Result.new(order: order, error_record: order)
    end
  end
end
