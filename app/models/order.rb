# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :user
  belongs_to :shop
  has_many :order_items, dependent: :destroy
  has_many :order_events, dependent: :destroy

  before_validation :populate_trust_snapshots, on: :create

  enum :status, {
    created: 0,
    accepted: 1,
    in_progress: 2,
    ready: 3,
    completed: 4,
    rejected_by_seller: 5,
    canceled_by_user: 6,
    canceled_by_seller: 7
  }, prefix: true

  validates :status, :total_price, :order_number, presence: true
  validates :shop_snapshot, :legal_profile_snapshot, :customer_snapshot, presence: true
  validates :total_price, numericality: { greater_than_or_equal_to: 0 }
  validates :order_number, numericality: { greater_than: 0, only_integer: true }

  # @return [String, nil]
  def last_public_comment
    order_events.public_commentable.order(created_at: :desc).limit(1).pick(:comment)
  end

  # @param event_type [Symbol, String]
  # @param actor_user [User, nil]
  # @param from_status [String, Symbol, nil]
  # @param to_status [String, Symbol, nil]
  # @param comment [String, nil]
  # @param metadata [Hash]
  # @return [OrderEvent]
  def record_event!(event_type:, actor_user:, from_status:, to_status:, comment: nil, metadata: {})
    order_events.create!(
      event_type: event_type,
      actor_user: actor_user,
      from_status: from_status,
      to_status: to_status,
      comment: comment,
      metadata: metadata
    )
  end

  private

  def populate_trust_snapshots
    return if shop.blank?
    return if shop_snapshot.present? && legal_profile_snapshot.present?

    snapshots = OrderSnapshots::Build.new(shop: shop).call
    self.shop_snapshot = snapshots[:shop_snapshot] if shop_snapshot.blank?
    self.legal_profile_snapshot = snapshots[:legal_profile_snapshot] if legal_profile_snapshot.blank?
  end
end
