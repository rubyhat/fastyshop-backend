require "rails_helper"

RSpec.describe ProductCategories::Restore do
  it "restores only selected category to draft" do
    owner = create(:user, role: :seller)
    parent = create(:product_category)
    child = create(:product_category, shop: parent.shop, parent: parent)
    product = create(:product, shop: parent.shop, product_category: child)

    ProductCategories::Archive.new(category: parent, actor_user: owner).call

    result = described_class.new(category: parent.reload, actor_user: owner).call

    expect(result).to be_success
    expect(parent.reload).to be_draft
    expect(child.reload).to be_archived
    expect(product.reload).to be_archived
    expect(parent.lifecycle_events.restored.exists?).to be(true)
  end
end
