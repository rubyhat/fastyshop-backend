require 'rails_helper'

RSpec.describe "Api::V1::Shops", type: :request do
  # let(:password) { "Password@123!" }
  # let(:user) { create(:user, role: :seller, password: password, password_confirmation: password) }
  let(:user) { create(:user) }

  describe "POST /api/v1/shops" do
    context "с валидными параметрами" do
      it "создаёт магазин" do
        seller_profile = create(:seller_profile, user: user)
        legal_profile = create(:legal_profile, seller_profile: seller_profile)
        shop_category = create(:shop_category)

        post "/api/v1/shops", headers: auth_headers(user), params: {
          title: "Flowers",
          contact_phone: "+77001234567",
          contact_email: "flowers@example.com",
          physical_address: "Алматы, Байзакова 1",
          shop_type: "online",
          shop_category_id: shop_category.id,
          legal_profile_id: legal_profile.id
        }

        expect(response).to have_http_status(:created)
        expect(json_body["title"]).to eq("Flowers")
        expect(json_body["slug"]).to be_present
      end
    end

    context "если нет seller_profile" do
      it "возвращает 403" do
        post "/api/v1/shops", headers: auth_headers(user), params: {
          title: "Без профиля",
          contact_phone: "+77001234567"
        }

        expect(response).to have_http_status(:forbidden)
        expect(json_body["error"]["message"]).to match(/профиль продавца/i)
      end
    end

    context "если неавторизован" do
      it "возвращает 401" do
        post "/api/v1/shops", headers: {}, params: {
          title: "Магазин без токена"
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
