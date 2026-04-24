require "rails_helper"

RSpec.describe Order, type: :model do
  it "stores immutable shop and legal snapshots" do
    order = create(:order)
    original_shop_title = order.shop_snapshot["title"]
    original_legal_name = order.legal_profile_snapshot["legal_name"]

    order.shop.update!(title: "Новое название магазина")
    order.shop.legal_profile.update!(legal_name: "Новое юрлицо")

    order.reload

    expect(order.shop_snapshot["title"]).to eq(original_shop_title)
    expect(order.legal_profile_snapshot["legal_name"]).to eq(original_legal_name)
  end

  it "requires customer snapshot" do
    order = build(:order, customer_snapshot: {})
    order.customer_snapshot = {}

    expect(order).to be_invalid
    expect(order.errors[:customer_snapshot]).to be_present
  end

  it "returns last public comment from terminal cancel/reject event" do
    order = create(:order)
    create(:order_event, order: order, event_type: :accepted, from_status: "created", to_status: "accepted", comment: nil)
    create(:order_event, order: order, event_type: :canceled_by_seller, from_status: "accepted", to_status: "canceled_by_seller", comment: "Товар закончился")

    expect(order.last_public_comment).to eq("Товар закончился")
  end
end
