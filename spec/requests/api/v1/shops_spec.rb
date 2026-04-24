require "rails_helper"

RSpec.describe "Api::V1::Shops", type: :request do
  let(:seller) { create(:user, role: :seller) }
  let(:seller_profile) { create(:seller_profile, user: seller) }
  let(:legal_profile) { create(:legal_profile, seller_profile: seller_profile) }
  let(:shop_category) { create(:shop_category) }

  describe "POST /api/v1/shops" do
    context "with valid params" do
      it "creates active shop with manual slug" do
        post "/api/v1/shops", headers: auth_headers(seller), params: {
          title: "Flowers",
          slug: "flowers-kz",
          description: "Цветы с доставкой",
          logo_url: "https://cdn.example.com/shops/flowers.png",
          contact_phone: "+77001234567",
          contact_email: "flowers@example.com",
          physical_address: "Алматы, Байзакова 1",
          shop_type: "online",
          shop_category_id: shop_category.id,
          legal_profile_id: legal_profile.id
        }

        expect(response).to have_http_status(:created)
        expect(json_body["title"]).to eq("Flowers")
        expect(json_body["slug"]).to eq("flowers-kz")
        expect(json_body["status"]).to eq("active")
        expect(ShopChangeEvent.created.count).to eq(1)
      end
    end

    it "returns 403 when seller profile does not exist" do
      seller_without_profile = create(:user, role: :seller)

      post "/api/v1/shops", headers: auth_headers(seller_without_profile), params: {
        title: "Без профиля",
        slug: "no-profile-shop",
        contact_phone: "+77001234567"
      }

      expect(response).to have_http_status(:forbidden)
      expect(json_body["error"]["message"]).to match(/профиль продавца/i)
    end

    it "rejects blocklisted slug" do
      create(:slug_blocklist_entry, term: "blocked-shop", match_type: :exact)

      post "/api/v1/shops", headers: auth_headers(seller), params: {
        title: "Blocked Shop",
        slug: "blocked-shop",
        contact_phone: "+77001234567",
        shop_type: "online",
        shop_category_id: shop_category.id,
        legal_profile_id: legal_profile.id
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "details", "slug")).to include(a_string_including("Этот адрес магазина нельзя использовать"))
    end

    it "rejects legal profile from another seller" do
      seller_profile
      other_legal_profile = create(:legal_profile)

      post "/api/v1/shops", headers: auth_headers(seller), params: {
        title: "Wrong Legal",
        slug: "wrong-legal",
        contact_phone: "+77001234567",
        shop_type: "online",
        shop_category_id: shop_category.id,
        legal_profile_id: other_legal_profile.id
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "details", "legal_profile_id")).to include(a_string_including("Вы не можете использовать чужой юридический профиль"))
    end
  end

  describe "PATCH /api/v1/shops/:id" do
    let(:shop) { create(:shop, seller_profile: seller_profile, legal_profile: legal_profile, slug: "old-flowers") }

    it "updates shop core fields and stores slug history" do
      patch "/api/v1/shops/#{shop.id}", headers: auth_headers(seller), params: {
        slug: "new-flowers",
        title: "New Flowers"
      }

      expect(response).to have_http_status(:ok)
      expect(json_body["slug"]).to eq("new-flowers")
      expect(shop.reload.slug_histories.pluck(:slug)).to include("old-flowers")
    end

    it "allows owner to change legal profile within same seller profile" do
      new_legal_profile = create(:legal_profile, seller_profile: seller_profile, legal_name: "TOO New Shop Legal")

      patch "/api/v1/shops/#{shop.id}", headers: auth_headers(seller), params: {
        legal_profile_id: new_legal_profile.id
      }

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("legal_profile", "id")).to eq(new_legal_profile.id)
    end

    it "forbids another seller from updating shop" do
      other_seller = create(:user, role: :seller)
      create(:seller_profile, user: other_seller)

      patch "/api/v1/shops/#{shop.id}", headers: auth_headers(other_seller), params: {
        title: " чужой апдейт"
      }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "shop lifecycle endpoints" do
    let(:shop) { create(:shop, seller_profile: seller_profile, legal_profile: legal_profile, status: :active) }

    it "allows owner to disable and activate own shop" do
      post "/api/v1/shops/#{shop.id}/disable", headers: auth_headers(seller)

      expect(response).to have_http_status(:ok)
      expect(json_body["status"]).to eq("disabled_by_owner")

      post "/api/v1/shops/#{shop.id}/activate", headers: auth_headers(seller)

      expect(response).to have_http_status(:ok)
      expect(json_body["status"]).to eq("active")
    end

    it "allows admin to suspend shop with owner-facing reason" do
      admin = create(:user, role: :superadmin)

      post "/api/v1/shops/#{shop.id}/suspend", headers: auth_headers(admin), params: {
        comment: "Нарушение правил платформы"
      }

      expect(response).to have_http_status(:ok)
      expect(json_body["status"]).to eq("suspended_by_admin")
      expect(json_body["status_comment"]).to eq("Нарушение правил платформы")
    end

    it "forbids owner from activating admin-suspended shop" do
      shop.update!(status: :suspended_by_admin, status_comment: "Нарушение правил")

      post "/api/v1/shops/#{shop.id}/activate", headers: auth_headers(seller)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
