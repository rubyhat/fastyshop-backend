require "rails_helper"

RSpec.describe Shops::ChangeStatus do
  let(:owner) { create(:user, role: :seller) }
  let(:seller_profile) { create(:seller_profile, user: owner) }
  let(:shop) { create(:shop, seller_profile: seller_profile, status: :active) }

  it "allows owner to disable shop" do
    result = described_class.new(
      shop: shop,
      actor_user: owner,
      target_status: :disabled_by_owner
    ).call

    expect(result).to be_success
    expect(shop.reload).to be_disabled_by_owner
  end

  it "does not allow owner to restore admin suspended shop" do
    shop.update!(status: :suspended_by_admin, status_comment: "Нарушение правил")

    result = described_class.new(
      shop: shop,
      actor_user: owner,
      target_status: :active
    ).call

    expect(result).not_to be_success
    expect(shop.reload).to be_suspended_by_admin
  end

  it "requires comment for admin suspend" do
    admin = create(:user, role: :superadmin)

    result = described_class.new(
      shop: shop,
      actor_user: admin,
      target_status: :suspended_by_admin
    ).call

    expect(result).not_to be_success
    expect(shop.errors[:status_comment]).to include("Укажите причину отключения магазина")
  end

  it "allows admin to restore suspended shop" do
    admin = create(:user, role: :superadmin)
    shop.update!(status: :suspended_by_admin, status_comment: "Нарушение правил")

    result = described_class.new(
      shop: shop,
      actor_user: admin,
      target_status: :active
    ).call

    expect(result).to be_success
    expect(shop.reload).to be_active
    expect(shop.status_comment).to be_nil
  end
end
