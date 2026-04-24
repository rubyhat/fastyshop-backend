require "rails_helper"

RSpec.describe OrderSnapshots::Build do
  it "builds immutable shop and legal profile trust snapshots" do
    legal_profile = create(
      :legal_profile,
      legal_form_code: "limited_liability_partnership",
      registration_number_type: "bin",
      registration_number: "123456789012",
      legal_address: "Алматы, Абая 1",
      verification_status: :approved
    )
    shop = create(:shop, legal_profile: legal_profile, seller_profile: legal_profile.seller_profile, slug: "snapshot-shop")

    snapshots = described_class.new(shop: shop).call

    expect(snapshots.dig(:shop_snapshot, :slug)).to eq("snapshot-shop")
    expect(snapshots.dig(:shop_snapshot, :verified_badge)).to be(true)
    expect(snapshots.dig(:legal_profile_snapshot, :registration_number_public)).to eq("123456789012")
    expect(snapshots.dig(:legal_profile_snapshot, :legal_address_public)).to eq("Алматы, Абая 1")
  end
end
