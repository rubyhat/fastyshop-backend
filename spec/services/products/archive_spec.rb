require "rails_helper"

RSpec.describe Products::Archive do
  it "archives product and records lifecycle event" do
    owner = create(:user, role: :seller)
    product = create(:product)

    result = described_class.new(product: product, actor_user: owner).call

    expect(result).to be_success
    expect(product.reload).to be_archived
    expect(product.archived_by).to eq(owner)
    expect(product.lifecycle_events.archived.exists?).to be(true)
  end
end
