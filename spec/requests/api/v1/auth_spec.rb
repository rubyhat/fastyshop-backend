require 'swagger_helper'

RSpec.describe 'Авторизация', swagger_doc: 'v1/swagger.yaml', type: :request do
  before do
    Country.find_or_create_by!(code: "KZ") do |country|
      country.name = "Казахстан"
      country.phone_prefix = "+7"
    end
  end

  path '/api/v1/auth/signup' do
    post 'Регистрация пользователя' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              phone: { type: :string, example: '+7 (700) 123-45-67' },
              email: { type: :string, example: 'USER@example.com' },
              password: { type: :string, example: 'SecurePass123!' },
              password_confirmation: { type: :string, example: 'SecurePass123!' },
              country_code: { type: :string, example: 'KZ' }
            },
            required: %w[phone email password password_confirmation country_code]
          }
        },
        required: %w[user]
      }

      response '201', 'Успешная регистрация' do
        let(:Authorization) { nil }
        let(:payload) do
          {
            user: {
              phone: '+7 (700) 123-45-67',
              email: 'USER@example.com',
              password: 'SecurePass123!',
              password_confirmation: 'SecurePass123!',
              country_code: 'KZ'
            }
          }
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          user = User.find_by!(phone: '77001234567')

          expect(json['access_token']).to be_present
          expect(json['refresh_token']).to be_present
          expect(json.dig('user', 'id')).to eq(user.id)
          expect(json.dig('user', 'phone')).to eq('77001234567')
          expect(json.dig('user', 'email')).to eq('user@example.com')
          expect(json.dig('user', 'role')).to eq('user')
          expect(json.dig('user', 'account_status')).to eq('pending_review')
        end
      end

      response '422', 'Невалидные параметры' do
        let(:Authorization) { nil }
        let(:payload) do
          {
            user: {
              phone: '+7 (700) 123-45-67',
              email: 'invalid-email',
              password: 'пароль',
              password_confirmation: 'пароль',
              country_code: 'KZ'
            }
          }
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.dig('error', 'key')).to eq('validation.failed')
          expect(json.dig('error', 'details')).to be_present
        end
      end
    end
  end

  path '/api/v1/auth/login' do
    post 'Аутентификация пользователя' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          phone: { type: :string, example: '+77001234567' },
          password: { type: :string, example: 'SecurePass123!' }
        },
        required: %w[phone password]
      }

      response '200', 'Успешный вход' do
        let(:Authorization) { nil }
        let!(:user) { create(:user, phone: '77001234567', password: 'SecurePass123!', password_confirmation: 'SecurePass123!') }
        let(:credentials) { { phone: '+7 (700) 123-45-67', password: 'SecurePass123!' } }

        run_test! do |response|
          json = JSON.parse(response.body)
          access_payload = JwtService.decode(json['access_token'])

          expect(json['access_token']).to be_present
          expect(json['refresh_token']).to be_present
          expect(json.dig('user', 'id')).to eq(user.id)
          expect(json.dig('user', 'phone')).to eq(user.phone)
          expect(json.dig('user', 'account_status')).to eq(user.account_status)
          expect(access_payload.keys).not_to include('phone', 'email', 'first_name', 'last_name', 'middle_name')
          expect(access_payload['sid']).to be_present
        end
      end

      response '401', 'Неверный пароль' do
        let(:Authorization) { nil }
        let(:user) { create(:user, phone: '77001234567', password: 'SecurePass123!', password_confirmation: 'SecurePass123!') }
        let(:credentials) { { phone: user.phone, password: 'wrong-password' } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.dig('error', 'key')).to eq('auth.invalid_credentials')
        end
      end

      response '401', 'Пользователь не найден' do
        let(:Authorization) { nil }
        let(:credentials) { { phone: '+79999999999', password: 'irrelevant' } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.dig('error', 'key')).to eq('auth.invalid_credentials')
        end
      end
    end
  end

  describe "refresh sessions" do
    let(:user) { create(:user, phone: "77001234567", password: "SecurePass123!", password_confirmation: "SecurePass123!") }

    it "поддерживает несколько refresh-сессий одного пользователя" do
      first_session = login_user(user)
      second_session = login_user(user)

      post "/api/v1/auth/refresh", params: { refresh_token: first_session.fetch("refresh_token") }

      expect(response).to have_http_status(:ok)
      expect(json_body["refresh_token"]).to be_present

      post "/api/v1/auth/refresh", params: { refresh_token: second_session.fetch("refresh_token") }

      expect(response).to have_http_status(:ok)
      expect(json_body["refresh_token"]).to be_present
    end

    it "logout очищает только текущую refresh-сессию" do
      first_session = login_user(user)
      second_session = login_user(user)

      post "/api/v1/auth/logout", headers: { "Authorization" => "Bearer #{first_session.fetch('access_token')}" }

      expect(response).to have_http_status(:ok)

      post "/api/v1/auth/refresh", params: { refresh_token: first_session.fetch("refresh_token") }

      expect(response).to have_http_status(:unauthorized)

      post "/api/v1/auth/refresh", params: { refresh_token: second_session.fetch("refresh_token") }

      expect(response).to have_http_status(:ok)
    end

    private

    def login_user(user)
      post "/api/v1/auth/login", params: { phone: user.phone, password: "SecurePass123!" }

      expect(response).to have_http_status(:ok)
      json_body.to_h
    end
  end
end
