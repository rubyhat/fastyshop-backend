require "rails_helper"

RSpec.describe Products::Publish do
  it "publishes valid product without category" do
    owner = create(:user, role: :seller)
    product = create(:product, :draft, :without_category)

    result = described_class.new(product: product, actor_user: owner).call

    expect(result).to be_success
    expect(product.reload).to be_published
  end

  it "rejects product when category is draft" do
    owner = create(:user, role: :seller)
    category = create(:product_category, :draft)
    product = create(:product, :draft, shop: category.shop, product_category: category)

    result = described_class.new(product: product, actor_user: owner).call

    expect(result).not_to be_success
    expect(product.errors[:product_category_id]).to include("категория должна быть опубликована перед публикацией товара")
  end
end
