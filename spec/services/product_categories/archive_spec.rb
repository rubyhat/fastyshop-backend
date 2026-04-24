require "rails_helper"

RSpec.describe ProductCategories::Archive do
  it "archives category subtree and products transactionally" do
    owner = create(:user, role: :seller)
    seller_profile = create(:seller_profile, user: owner)
    shop = create(:shop, seller_profile: seller_profile)
    parent = create(:product_category, shop: shop, title: "Parent")
    child = create(:product_category, shop: shop, parent: parent, title: "Child")
    product = create(:product, shop: shop, product_category: child)

    result = described_class.new(category: parent, actor_user: owner).call

    expect(result).to be_success
    expect(parent.reload).to be_archived
    expect(child.reload).to be_archived
    expect(product.reload).to be_archived
    expect(result.preview[:affected]).to include(child_categories_count: 1, products_count: 1)
  end
end
