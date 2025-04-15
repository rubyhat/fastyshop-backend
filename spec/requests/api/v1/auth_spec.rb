require 'rails_helper'

RSpec.describe "Api::V1::Auth", type: :request do
  let(:password) { "SecurePass123!" }

  let!(:user) do
    create(:user, phone: "+77001234567", password: password, password_confirmation: password)
  end

  describe "POST /api/v1/auth/login" do
    context "с корректными данными" do
      it "возвращает access_token и refresh_token" do
        post "/api/v1/auth/login", params: {
          phone: user.phone,
          password: password
        }

        expect(response).to have_http_status(:ok)
        expect(json_body["access_token"]).to be_present
        expect(json_body["refresh_token"]).to be_present
      end
    end

    context "с некорректным паролем" do
      it "возвращает 401" do
        post "/api/v1/auth/login", params: {
          phone: user.phone,
          password: "wrong-password"
        }

        expect(response).to have_http_status(:unauthorized)
        expect(json_body["error"]).to be_present
      end
    end

    context "с несуществующим телефоном" do
      it "возвращает 401" do
        post "/api/v1/auth/login", params: {
          phone: "+79999999999",
          password: "irrelevant"
        }

        expect(response).to have_http_status(:unauthorized)
        expect(json_body["error"]).to be_present
      end
    end
  end
end
