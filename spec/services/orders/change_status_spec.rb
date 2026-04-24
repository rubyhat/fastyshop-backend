require "rails_helper"

RSpec.describe Orders::ChangeStatus do
  let(:shop) { create(:shop) }
  let(:seller) { shop.seller_profile.user }
  let(:buyer) { create(:user) }

  it "allows seller to accept order" do
    order = create(:order, user: buyer, shop: shop, status: :created)

    result = described_class.new(
      order: order,
      actor_user: seller,
      new_status: :accepted,
      comment: nil
    ).call

    expect(result).to be_success
    expect(order.reload).to be_status_accepted
    expect(order.order_events.last).to have_attributes(event_type: "accepted", from_status: "created", to_status: "accepted")
  end

  it "requires comment for seller rejection and restores stock once" do
    product = create(:product, shop: shop, stock_quantity: 1)
    order = create(:order, user: buyer, shop: shop, status: :created, inventory_restored_at: nil)
    create(:order_item, order: order, product: product, quantity: 1)
    product.decrement!(:stock_quantity, 1)

    result = described_class.new(
      order: order,
      actor_user: seller,
      new_status: :rejected_by_seller,
      comment: "Нет в наличии"
    ).call

    expect(result).to be_success
    expect(order.reload).to be_status_rejected_by_seller
    expect(order.inventory_restored_at).to be_present
    expect(product.reload.stock_quantity).to eq(1)

    replay = described_class.new(
      order: order,
      actor_user: seller,
      new_status: :rejected_by_seller,
      comment: "Нет в наличии"
    ).call

    expect(replay).to be_success
    expect(product.reload.stock_quantity).to eq(1)
  end

  it "allows buyer to cancel only created order" do
    order = create(:order, user: buyer, shop: shop, status: :accepted)

    result = described_class.new(
      order: order,
      actor_user: buyer,
      new_status: :canceled_by_user,
      comment: "Передумал"
    ).call

    expect(result).not_to be_success
    expect(result.error_record.errors[:base]).to include("У вас нет прав на это изменение статуса")
  end
end
