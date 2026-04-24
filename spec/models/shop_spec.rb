require "rails_helper"

RSpec.describe Shop, type: :model do
  describe "slug validation" do
    it "normalizes uppercase slug" do
      shop = build(:shop, slug: "Miras-Shop")

      expect(shop).to be_valid
      expect(shop.slug).to eq("miras-shop")
    end

    it "rejects spaces and underscores" do
      shop = build(:shop, slug: "miras_shop")

      expect(shop).to be_invalid
      expect(shop.errors[:slug]).to be_present
    end

    it "rejects double dashes" do
      shop = build(:shop, slug: "miras--shop")

      expect(shop).to be_invalid
      expect(shop.errors[:slug]).to be_present
    end

    it "rejects slug reserved by another shop history" do
      create(:shop_slug_history, slug: "reserved-slug")
      shop = build(:shop, slug: "reserved-slug")

      expect(shop).to be_invalid
      expect(shop.errors[:slug]).to include("уже использовался другим магазином")
    end

    it "rejects new slug from active blocklist" do
      create(:slug_blocklist_entry, term: "blocked-shop", match_type: :exact)
      shop = build(:shop, slug: "blocked-shop")

      expect(shop).to be_invalid
      expect(shop.errors[:slug]).to include("Этот адрес магазина нельзя использовать. Выберите другой slug.")
    end

    it "does not invalidate existing shop when its current slug is added to blocklist later" do
      shop = create(:shop, slug: "existing-shop")
      create(:slug_blocklist_entry, term: "existing-shop", match_type: :exact)

      shop.description = "Новый текст"

      expect(shop).to be_valid
      expect(shop.slug_policy[:action_required]).to be(true)
    end
  end

  describe "public storefront helpers" do
    it "hides physical address for online shops" do
      shop = build(:shop, shop_type: :online, physical_address: "Алматы, Абая 1")

      expect(shop.physical_address_public).to be_nil
    end

    it "shows physical address for hybrid shops" do
      shop = build(:shop, shop_type: :hybrid, physical_address: "Алматы, Абая 1")

      expect(shop.physical_address_public).to eq("Алматы, Абая 1")
    end

    it "marks disabled shop content as hidden" do
      shop = build(:shop, status: :disabled_by_owner)

      expect(shop.content_state).to eq("hidden")
      expect(shop.public_alert[:key]).to eq("shops.public.disabled_by_owner")
    end
  end
end
