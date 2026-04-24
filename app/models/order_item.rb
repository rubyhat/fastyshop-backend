# frozen_string_literal: true

class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  before_validation :populate_product_snapshot, on: :create

  validates :product_snapshot, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  private

  def populate_product_snapshot
    return if product.blank?
    return if product_snapshot.present?

    self.product_snapshot = OrderItemSnapshots::Build.new(product: product).call
  end
end
