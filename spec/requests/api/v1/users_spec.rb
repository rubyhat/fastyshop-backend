require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  describe "GET /api/v1/me" do
    let(:user) { create(:user, password: "Password123!", password_confirmation: "Password123!") }

    context "когда пользователь авторизован" do
      it "возвращает текущего пользователя" do
        get "/api/v1/me", headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_body["id"]).to eq(user.id)
        expect(json_body["phone"]).to eq(user.phone)
      end
    end

    context "когда токен не передан" do
      it "возвращает 401" do
        get "/api/v1/me"

        expect(response).to have_http_status(:unauthorized)
        expect(json_body["error"]).to be_present
      end
    end

    context "когда передан невалидный токен" do
      it "возвращает 401" do
        get "/api/v1/me", headers: { "Authorization" => "Bearer invalid.token.value" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_body.dig("error", "key")).to eq("auth.unauthorized")
      end
    end
  end

  describe "PATCH /api/v1/users/:id" do
    let(:user) { create(:user, role: :user) }
    let(:other_user) { create(:user, role: :user) }

    context "когда пользователь пытается обновить чужой профиль" do
      it "возвращает 403" do
        patch "/api/v1/users/#{other_user.id}", headers: auth_headers(user), params: {
          first_name: "Forbidden"
        }

        expect(response).to have_http_status(:forbidden)
        expect(json_body.dig("error", "key")).to eq("auth.pundit.forbidden")
      end
    end
  end
end
