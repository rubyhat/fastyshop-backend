require "rails_helper"

RSpec.describe "Api::V1::SellerOnboarding", type: :request do
  let(:user) { create(:user, role: :user) }
  let(:shop_category) { create(:shop_category) }

  let(:params) do
    {
      seller_profile: {
        display_name: "Miras Store Group",
        description: "Описание продавца",
        logo_url: "https://cdn.example.com/logo.png"
      },
      legal_profile: {
        country_code: "KZ",
        legal_form_code: "limited_liability_partnership",
        legal_name: "TOO Miras Trade",
        registration_number_type: "bin",
        registration_number: "123456789012",
        legal_address: "Алматы, Абая 1"
      },
      shop: {
        title: "Miras Flowers",
        slug: "miras-flowers",
        description: "Магазин цветов с доставкой",
        logo_url: "https://cdn.example.com/shops/miras-flowers.png",
        contact_phone: "+77001234567",
        contact_email: "shop@example.com",
        physical_address: "Алматы, Байзакова 10",
        shop_type: "online",
        shop_category_id: shop_category.id
      }
    }
  end

  describe "POST /api/v1/seller_onboarding" do
    it "creates seller profile, legal profile and shop in one request" do
      post "/api/v1/seller_onboarding", headers: auth_headers(user), params: params

      expect(response).to have_http_status(:created)
      expect(json_body.dig("seller_profile", "slug")).to eq("miras-store-group")
      expect(json_body.dig("legal_profile", "verification_status")).to eq("draft")
      expect(json_body.dig("shop", "slug")).to eq("miras-flowers")
      expect(user.reload.role).to eq("seller")
      expect(user.seller_profile).to be_present
      expect(LegalProfile.count).to eq(1)
      expect(Shop.count).to eq(1)
    end

    it "rolls back all entities when legal profile is invalid" do
      post "/api/v1/seller_onboarding",
           headers: auth_headers(user),
           params: params.deep_merge(legal_profile: { country_code: "RU" })

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "details", "country_code")).to include(a_string_including("страна временно не поддерживается для продавцов"))
      expect(user.reload.role).to eq("user")
      expect(user.seller_profile).to be_nil
      expect(LegalProfile.count).to eq(0)
      expect(Shop.count).to eq(0)
    end

    it "rolls back all entities when shop is invalid" do
      post "/api/v1/seller_onboarding",
           headers: auth_headers(user),
           params: params.deep_merge(shop: { title: nil })

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "details", "title")).to include(a_string_including("can't be blank"))
      expect(user.reload.role).to eq("user")
      expect(user.seller_profile).to be_nil
      expect(LegalProfile.count).to eq(0)
      expect(Shop.count).to eq(0)
    end

    it "returns 422 when onboarding is requested again after seller profile already exists" do
      create(:seller_profile, user: user)

      post "/api/v1/seller_onboarding", headers: auth_headers(user), params: params

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "details", "base")).to include("Профиль продавца уже существует")
    end
  end
end
