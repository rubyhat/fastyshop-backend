# frozen_string_literal: true

module Orders
  # AllocateNumber returns the next human-friendly order number inside one shop.
  class AllocateNumber
    # @param shop [Shop]
    def initialize(shop:)
      @shop = shop
    end

    # @return [Integer]
    def call
      shop.with_lock do
        shop.orders_counter += 1
        shop.save!
        shop.orders_counter
      end
    end

    private

    attr_reader :shop
  end
end
