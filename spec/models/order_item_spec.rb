require "rails_helper"

RSpec.describe OrderItem, type: :model do
  it "stores immutable product snapshot on create" do
    product = create(:product, title: "Букет роз", sku: "ROSE-001")
    order = create(:order, shop: product.shop)

    order_item = create(:order_item, order: order, product: product)
    product.update!(title: "Новое название")

    expect(order_item.reload.product_snapshot["title"]).to eq("Букет роз")
    expect(order_item.product_snapshot["sku"]).to eq("ROSE-001")
  end
end
