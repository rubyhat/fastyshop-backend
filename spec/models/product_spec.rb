require "rails_helper"

RSpec.describe Product, type: :model do
  it "defaults to draft when created without explicit status" do
    product = described_class.create!(
      shop: create(:shop),
      title: "Новый товар",
      price: 1000,
      product_type: :physical,
      stock_quantity: 1
    )

    expect(product).to be_draft
  end

  it "can exist without category" do
    product = build(:product, :without_category)

    expect(product).to be_valid
  end

  it "returns out_of_stock availability for published physical product with zero stock" do
    product = create(:product, stock_quantity: 0)

    expect(product.availability).to eq("out_of_stock")
    expect(product).not_to be_available_for_cart
  end

  it "returns unavailable availability for draft product" do
    product = create(:product, :draft)

    expect(product.availability).to eq("unavailable")
  end

  it "does not allow archived product edits before restore" do
    product = create(:product, :archived)

    product.title = "Новое название"

    expect(product).to be_invalid
    expect(product.errors[:base]).to include("Архивированный товар нельзя редактировать. Сначала восстановите его из архива.")
  end

  it "prevents hard destroy" do
    product = create(:product)

    expect(product.destroy).to be(false)
    expect(product.errors[:base]).to include("Товар нельзя удалить полностью. Используйте архивирование.")
  end
end
