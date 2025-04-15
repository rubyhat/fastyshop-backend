
require 'swagger_helper'

RSpec.describe 'Авторизация', swagger_doc: 'v1/swagger.yaml', type: :request do
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
        let(:user) { create(:user, phone: '+77001234567', password: 'SecurePass123!', password_confirmation: 'SecurePass123!') }
        let(:credentials) { { phone: user.phone, password: 'SecurePass123!' } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['access_token']).to be_present
          expect(json['refresh_token']).to be_present
        end
      end

      response '401', 'Неверный пароль' do
        let(:Authorization) { nil }
        let(:user) { create(:user, phone: '+77001234567', password: 'SecurePass123!', password_confirmation: 'SecurePass123!') }
        let(:credentials) { { phone: user.phone, password: 'wrong-password' } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['error']).to be_present
        end
      end

      response '401', 'Пользователь не найден' do
        let(:Authorization) { nil }
        let(:credentials) { { phone: '+79999999999', password: 'irrelevant' } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['error']).to be_present
        end
      end
    end
  end
end
