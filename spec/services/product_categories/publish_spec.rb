require "rails_helper"

RSpec.describe ProductCategories::Publish do
  it "publishes category with published parent" do
    owner = create(:user, role: :seller)
    parent = create(:product_category)
    child = create(:product_category, :draft, shop: parent.shop, parent: parent)

    result = described_class.new(category: child, actor_user: owner).call

    expect(result).to be_success
    expect(child.reload).to be_published
    expect(child.published_by).to eq(owner)
  end

  it "rejects category with draft parent" do
    owner = create(:user, role: :seller)
    parent = create(:product_category, :draft)
    child = create(:product_category, :draft, shop: parent.shop, parent: parent)

    result = described_class.new(category: child, actor_user: owner).call

    expect(result).not_to be_success
    expect(child.errors[:parent_id]).to include("родительская категория должна быть опубликована")
  end
end
