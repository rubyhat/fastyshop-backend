require "rails_helper"

RSpec.describe SellerProfile, type: :model do
  describe "slug behavior" do
    it "generates slug on create" do
      profile = create(:seller_profile, display_name: "Miras Flowers")

      expect(profile.slug).to eq("miras-flowers")
    end

    it "keeps slug immutable after create" do
      profile = create(:seller_profile)
      original_slug = profile.slug

      expect(profile.update(slug: "changed-slug")).to be(false)
      expect(profile.errors[:slug]).to include("нельзя изменить после создания")
      expect(profile.reload.slug).to eq(original_slug)
    end
  end
end
