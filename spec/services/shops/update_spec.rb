require "rails_helper"

RSpec.describe Shops::Update do
  let(:actor_user) { create(:user, role: :seller) }
  let(:seller_profile) { create(:seller_profile, user: actor_user) }
  let(:shop) { create(:shop, seller_profile: seller_profile, slug: "old-shop", title: "Old Shop") }

  it "stores old slug in history and records trust event" do
    result = described_class.new(
      shop: shop,
      actor_user: actor_user,
      attributes: { slug: "new-shop" }
    ).call

    expect(result).to be_success
    expect(shop.reload.slug).to eq("new-shop")
    expect(shop.slug_histories.pluck(:slug)).to include("old-shop")
    expect(shop.change_events.slug_changed.last.changeset).to include("from" => "old-shop", "to" => "new-shop")
  end

  it "does not record trust event for description-only updates" do
    expect {
      described_class.new(
        shop: shop,
        actor_user: actor_user,
        attributes: { description: "Новый текст" }
      ).call
    }.not_to change(ShopChangeEvent, :count)
  end

  it "records legal profile changes with public legal names" do
    new_legal_profile = create(:legal_profile, seller_profile: seller_profile, legal_name: "TOO New Legal")

    result = described_class.new(
      shop: shop,
      actor_user: actor_user,
      attributes: { legal_profile_id: new_legal_profile.id }
    ).call

    expect(result).to be_success
    event = shop.change_events.legal_profile_changed.last
    expect(event.changeset["to"]).to eq("TOO New Legal")
  end
end
