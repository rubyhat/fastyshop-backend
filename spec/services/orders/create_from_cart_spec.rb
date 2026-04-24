require "rails_helper"

RSpec.describe Orders::CreateFromCart do
  let(:buyer) { create(:user) }
  let(:shop) { create(:shop) }

  it "creates order for valid items and keeps skipped items in cart" do
    valid_product = create(:product, shop: shop, title: "Valid", stock_quantity: 3, price: 1500)
    skipped_product = create(:product, shop: shop, title: "Skipped", stock_quantity: 1, price: 900)
    cart = create(:cart, user: buyer, shop: shop)
    create(:cart_item, cart: cart, product: valid_product, quantity: 1, price_snapshot: 1000)
    create(:cart_item, cart: cart, product: skipped_product, quantity: 1, price_snapshot: 900)
    skipped_product.update!(stock_quantity: 0)

    result = described_class.new(
      user: buyer,
      shop: shop,
      cart: cart,
      idempotency_key: "checkout-1",
      contact_name: nil,
      contact_phone: nil,
      customer_comment: "Комментарий"
    ).call

    expect(result).to be_success
    expect(result.order.order_items.size).to eq(1)
    expect(result.order.total_price).to eq(BigDecimal("1500"))
    expect(result.checkout_summary[:skipped_items].size).to eq(1)
    expect(result.checkout_summary[:price_changed_items].size).to eq(1)
    expect(cart.reload).to be_active
    expect(cart.cart_items.pluck(:product_id)).to contain_exactly(skipped_product.id)
    expect(valid_product.reload.stock_quantity).to eq(2)
  end

  it "returns replayed result for the same idempotency key" do
    product = create(:product, shop: shop, stock_quantity: 3)
    cart = create(:cart, user: buyer, shop: shop)
    create(:cart_item, cart: cart, product: product, quantity: 1)

    first_result = described_class.new(
      user: buyer,
      shop: shop,
      cart: cart,
      idempotency_key: "same-key",
      contact_name: nil,
      contact_phone: nil,
      customer_comment: nil
    ).call

    replay_result = described_class.new(
      user: buyer,
      shop: shop,
      cart: buyer.carts.active_state.find_by(shop_id: shop.id),
      idempotency_key: "same-key",
      contact_name: nil,
      contact_phone: nil,
      customer_comment: nil
    ).call

    expect(first_result).to be_success
    expect(replay_result).to be_success
    expect(replay_result.replayed).to be(true)
    expect(replay_result.order.id).to eq(first_result.order.id)
  end

  it "blocks self purchase" do
    seller = shop.seller_profile.user
    own_shop = create(:shop, seller_profile: shop.seller_profile)
    cart = build(:cart, user: seller, shop: own_shop)

    result = described_class.new(
      user: seller,
      shop: own_shop,
      cart: cart,
      idempotency_key: "self-shop",
      contact_name: nil,
      contact_phone: nil,
      customer_comment: nil
    ).call

    expect(result).not_to be_success
    expect(result.error_key).to eq("order.self_purchase_forbidden")
  end
end
