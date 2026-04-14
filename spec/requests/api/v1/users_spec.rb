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
        expect(json_body["phone_display"]).to eq("+#{user.phone}")
        expect(json_body["account_status"]).to eq(user.account_status)
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

  describe "POST /api/v1/users" do
    let(:params) do
      {
        user: {
          phone: "+7 (700) 999-88-77",
          email: "ADMIN-CREATED@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          country_code: "KZ",
          role: "seller",
          account_status: "approved"
        }
      }
    end

    context "когда пользователь не авторизован" do
      it "возвращает 401" do
        post "/api/v1/users", params: params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "когда обычный пользователь пытается создать пользователя" do
      it "возвращает 403" do
        user = create(:user, role: :user)

        post "/api/v1/users", headers: auth_headers(user), params: params

        expect(response).to have_http_status(:forbidden)
        expect(json_body.dig("error", "key")).to eq("auth.pundit.forbidden")
      end
    end

    context "когда supermanager создаёт пользователя" do
      it "создаёт пользователя через admin flow" do
        admin = create(:user, role: :supermanager)

        post "/api/v1/users", headers: auth_headers(admin), params: params

        expect(response).to have_http_status(:created)
        expect(json_body["phone"]).to eq("77009998877")
        expect(json_body["email"]).to eq("admin-created@example.com")
        expect(json_body["role"]).to eq("seller")
        expect(json_body["account_status"]).to eq("approved")
      end
    end

    context "когда админ пытается создать superadmin" do
      it "возвращает 422" do
        admin = create(:user, role: :supermanager)

        post "/api/v1/users", headers: auth_headers(admin), params: params.deep_merge(user: { role: "superadmin" })

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_body.dig("error", "details", "role")).to be_present
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

    context "когда пользователь пытается изменить защищённые поля" do
      it "не меняет phone, country_code, role и account_status" do
        patch "/api/v1/users/#{user.id}", headers: auth_headers(user), params: {
          first_name: "Allowed",
          phone: "+77001112233",
          country_code: "RU",
          role: "seller",
          account_status: "blocked"
        }

        expect(response).to have_http_status(:ok)
        expect(user.reload.first_name).to eq("Allowed")
        expect(user.phone).not_to eq("77001112233")
        expect(user.country_code).to eq("KZ")
        expect(user.role).to eq("user")
        expect(user.account_status).to eq("approved")
      end
    end

    context "когда supermanager пытается изменить роль через общий endpoint профиля" do
      it "не меняет роль пользователя" do
        admin = create(:user, role: :supermanager)

        patch "/api/v1/users/#{user.id}", headers: auth_headers(admin), params: {
          role: "supermanager",
          first_name: "Changed By Admin"
        }

        expect(response).to have_http_status(:ok)
        expect(user.reload.first_name).to eq("Changed By Admin")
        expect(user.role).to eq("user")
      end
    end
  end

  describe "PATCH /api/v1/users/:id/account_status" do
    let(:target_user) { create(:user, account_status: :pending_review) }

    context "когда обычный пользователь пытается изменить статус" do
      it "возвращает 403" do
        user = create(:user, role: :user)

        patch "/api/v1/users/#{target_user.id}/account_status", headers: auth_headers(user), params: {
          account_status: "approved"
        }

        expect(response).to have_http_status(:forbidden)
        expect(json_body.dig("error", "key")).to eq("auth.pundit.forbidden")
      end
    end

    context "когда supermanager меняет статус" do
      it "обновляет account_status" do
        admin = create(:user, role: :supermanager)

        patch "/api/v1/users/#{target_user.id}/account_status", headers: auth_headers(admin), params: {
          account_status: "approved"
        }

        expect(response).to have_http_status(:ok)
        expect(json_body["account_status"]).to eq("approved")
        expect(target_user.reload.account_status).to eq("approved")
      end
    end

    context "когда передан неизвестный статус" do
      it "возвращает 422" do
        admin = create(:user, role: :supermanager)

        patch "/api/v1/users/#{target_user.id}/account_status", headers: auth_headers(admin), params: {
          account_status: "unknown"
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_body.dig("error", "details", "account_status")).to be_present
      end
    end
  end

  describe "GET /api/v1/users/:id" do
    let(:user) { create(:user, role: :user) }

    context "когда запрос не авторизован" do
      it "не раскрывает телефон и возвращает 401" do
        get "/api/v1/users/#{user.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "когда пользователь запрашивает себя" do
      it "возвращает приватные контактные поля" do
        get "/api/v1/users/#{user.id}", headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_body["phone"]).to eq(user.phone)
        expect(json_body["email"]).to eq(user.email)
      end
    end
  end
end
