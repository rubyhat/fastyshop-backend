require "rails_helper"

RSpec.describe ProductCategory, type: :model do
  it "defaults to draft when created without explicit status" do
    category = described_class.create!(
      shop: create(:shop),
      title: "Новая категория"
    )

    expect(category).to be_draft
  end

  it "supports deep nesting without fixed business depth limit" do
    shop = create(:shop)
    parent = create(:product_category, shop: shop)

    5.times do |index|
      parent = create(:product_category, shop: shop, parent: parent, title: "Level #{index}")
    end

    expect(parent.level).to eq(5)
    expect(parent).to be_valid
  end

  it "rejects cyclic parent assignment" do
    root = create(:product_category)
    child = create(:product_category, shop: root.shop, parent: root)

    root.parent = child

    expect(root).to be_invalid
    expect(root.errors[:parent_id]).to include("не может ссылаться на саму категорию или её потомка")
  end

  it "does not allow archived category edits before restore" do
    category = create(:product_category, :archived)

    category.title = "Новое название"

    expect(category).to be_invalid
    expect(category.errors[:base]).to include("Архивированную категорию нельзя редактировать. Сначала восстановите её из архива.")
  end

  it "prevents hard destroy" do
    category = create(:product_category)

    expect(category.destroy).to be(false)
    expect(category.errors[:base]).to include("Категорию нельзя удалить полностью. Используйте архивирование.")
  end
end
