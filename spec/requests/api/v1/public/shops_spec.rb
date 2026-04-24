require "rails_helper"

RSpec.describe "Api::V1::Public::Shops", type: :request do
  describe "GET /api/v1/public/shops/catalog" do
    it "returns only active shops" do
      active_shop = create(:shop, title: "Active Shop", slug: "active-shop", status: :active)
      create(:shop, title: "Disabled Shop", slug: "disabled-shop", status: :disabled_by_owner)
      create(:shop, title: "Suspended Shop", slug: "suspended-shop", status: :suspended_by_admin)

      get "/api/v1/public/shops/catalog"

      expect(response).to have_http_status(:ok)
      expect(json_body.pluck("slug")).to contain_exactly(active_shop.slug)
    end
  end

  describe "GET /api/v1/public/shops/:slug" do
    it "returns public shop payload by canonical slug" do
      legal_profile = create(:legal_profile, verification_status: :approved)
      shop = create(
        :shop,
        legal_profile: legal_profile,
        seller_profile: legal_profile.seller_profile,
        slug: "miras-flowers",
        shop_type: :hybrid,
        physical_address: "Алматы, Абая 1"
      )

      get "/api/v1/public/shops/#{shop.slug}"

      expect(response).to have_http_status(:ok)
      expect(json_body["slug"]).to eq("miras-flowers")
      expect(json_body["canonical_path"]).to eq("/shops/miras-flowers")
      expect(json_body["redirect_required"]).to be(false)
      expect(json_body["physical_address_public"]).to eq("Алматы, Абая 1")
      expect(json_body.dig("trust_summary", "registration_number_public")).to eq(legal_profile.registration_number)
    end

    it "resolves historical slug and returns redirect signal" do
      shop = create(:shop, slug: "new-shop")
      create(:shop_slug_history, shop: shop, slug: "old-shop")

      get "/api/v1/public/shops/old-shop"

      expect(response).to have_http_status(:ok)
      expect(json_body["slug"]).to eq("new-shop")
      expect(json_body["canonical_slug"]).to eq("new-shop")
      expect(json_body["redirect_required"]).to be(true)
    end

    it "returns limited payload for disabled shop without private status comment" do
      shop = create(
        :shop,
        slug: "disabled-shop",
        description: "Контент магазина",
        status: :suspended_by_admin,
        status_comment: "Внутренний комментарий модератора"
      )

      get "/api/v1/public/shops/#{shop.slug}"

      expect(response).to have_http_status(:ok)
      expect(json_body["content_state"]).to eq("hidden")
      expect(json_body["description"]).to be_nil
      expect(json_body.dig("public_alert", "key")).to eq("shops.public.suspended_by_admin")
      expect(response.body).not_to include("Внутренний комментарий модератора")
    end
  end

  describe "GET /api/v1/public/shops/:slug/legal_details" do
    it "returns legal details without IIN for person-based legal form" do
      legal_profile = create(:legal_profile, :individual_entrepreneur, verification_status: :approved)
      shop = create(:shop, legal_profile: legal_profile, seller_profile: legal_profile.seller_profile)

      get "/api/v1/public/shops/#{shop.slug}/legal_details"

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("legal_profile", "registration_number_type")).to eq("iin")
      expect(json_body.dig("legal_profile", "registration_number_public")).to be_nil
      expect(json_body.dig("legal_profile", "legal_address_public")).to be_nil
      expect(response.body).not_to include(legal_profile.registration_number)
    end

    it "can return public address for limited liability partnership" do
      legal_profile = create(
        :legal_profile,
        legal_form_code: "limited_liability_partnership",
        registration_number_type: "bin",
        registration_number: "123456789012",
        legal_address: "Алматы, Абая 1"
      )
      shop = create(:shop, legal_profile: legal_profile, seller_profile: legal_profile.seller_profile)

      get "/api/v1/public/shops/#{shop.slug}/legal_details"

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("legal_profile", "registration_number_public")).to eq("123456789012")
      expect(json_body.dig("legal_profile", "legal_address_public")).to eq("Алматы, Абая 1")
    end
  end

  describe "GET /api/v1/public/shops/:slug/change_history" do
    it "returns trust-critical shop changes" do
      shop = create(:shop, slug: "history-shop")
      create(:shop_change_event, shop: shop, event_type: :title_changed, changeset: { from: "Old", to: "New" })

      get "/api/v1/public/shops/#{shop.slug}/change_history"

      expect(response).to have_http_status(:ok)
      expect(json_body.first["event_type"]).to eq("title_changed")
      expect(json_body.first["summary"]).to eq("Изменено название магазина")
      expect(json_body.first["changes"]).to include("from" => "Old", "to" => "New")
    end
  end

  describe "public storefront content" do
    it "does not expose products for inactive shop" do
      shop = create(:shop, slug: "inactive-catalog-shop", status: :disabled_by_owner)
      product_category = create(:product_category, shop: shop)
      create(:product, shop: shop, product_category: product_category)

      get "/api/v1/public/shops/#{shop.slug}/products"

      expect(response).to have_http_status(:not_found)
    end
  end
end
