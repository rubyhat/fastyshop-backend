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
  end
end
