require "rails_helper"

RSpec.describe ProductCategories::Reorder do
  it "updates category positions inside one shop" do
    shop = create(:shop)
    first_category = create(:product_category, shop: shop, position: 1)
    second_category = create(:product_category, shop: shop, position: 2)

    result = described_class.new(
      shop: shop,
      positions: [
        { id: first_category.id, position: 2 },
        { id: second_category.id, position: 1 }
      ]
    ).call

    expect(result).to be_success
    expect(first_category.reload.position).to eq(2)
    expect(second_category.reload.position).to eq(1)
  end

  it "rejects categories from another shop" do
    shop = create(:shop)
    another_category = create(:product_category)

    result = described_class.new(
      shop: shop,
      positions: [
        { id: another_category.id, position: 1 }
      ]
    ).call

    expect(result).not_to be_success
    expect(result.error_record.errors[:base]).to include("Одна или несколько категорий не найдены")
  end
end
