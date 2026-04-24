require "rails_helper"

RSpec.describe Products::Restore do
  it "restores product to draft and records lifecycle event" do
    owner = create(:user, role: :seller)
    product = create(:product, :archived)

    result = described_class.new(product: product, actor_user: owner).call

    expect(result).to be_success
    expect(product.reload).to be_draft
    expect(product.archived_by).to be_nil
    expect(product.lifecycle_events.restored.exists?).to be(true)
  end
end
