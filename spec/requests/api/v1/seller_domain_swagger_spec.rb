require "swagger_helper"

RSpec.describe "Seller domain API", swagger_doc: "v1/swagger.yaml", type: :request do
  def bearer_for(user)
    "Bearer #{JwtService.generate_tokens(user)[:access_token]}"
  end

  let!(:country) do
    Country.find_or_create_by!(code: "KZ") do |record|
      record.name = "Казахстан"
      record.phone_prefix = "+7"
    end
  end

  let!(:shop_category) { create(:shop_category) }

  path "/api/v1/seller_profiles" do
    post "Создание профиля продавца" do
      tags "Seller profiles"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          display_name: { type: :string, example: "Miras Store Group" },
          description: { type: :string, example: "Описание продавца" },
          logo_url: { type: :string, example: "https://cdn.example.com/logo.png" }
        },
        required: %w[display_name]
      }

      response "201", "Профиль продавца создан" do
        let(:user) { create(:user, role: :user) }
        let(:Authorization) { bearer_for(user) }
        let(:payload) do
          {
            display_name: "Miras Store Group",
            description: "Описание продавца",
            logo_url: "https://cdn.example.com/logo.png"
          }
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["slug"]).to eq("miras-store-group")
        end
      end
    end
  end

  path "/api/v1/legal_profiles" do
    post "Создание юридического профиля" do
      tags "Legal profiles"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          country_code: { type: :string, example: "KZ" },
          legal_form_code: { type: :string, example: "limited_liability_partnership" },
          legal_name: { type: :string, example: "TOO Miras Trade" },
          registration_number_type: { type: :string, example: "bin" },
          registration_number: { type: :string, example: "123456789012" },
          legal_address: { type: :string, example: "Алматы, Абая 1" }
        },
        required: %w[country_code legal_form_code legal_name registration_number_type registration_number]
      }

      response "201", "Юридический профиль создан" do
        let(:user) { create(:user, role: :seller) }
        let!(:seller_profile) { create(:seller_profile, user: user) }
        let(:Authorization) { bearer_for(user) }
        let(:payload) do
          {
            country_code: "KZ",
            legal_form_code: "limited_liability_partnership",
            legal_name: "TOO Miras Trade",
            registration_number_type: "bin",
            registration_number: "123456789012",
            legal_address: "Алматы, Абая 1"
          }
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["verification_status"]).to eq("draft")
        end
      end
    end
  end

  path "/api/v1/legal_profiles/{id}/submit_verification" do
    post "Подача юридического профиля на ручную проверку" do
      tags "Legal profiles"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "Юридический профиль отправлен на проверку" do
        let(:user) { create(:user, role: :seller) }
        let!(:seller_profile) { create(:seller_profile, user: user) }
        let!(:legal_profile) { create(:legal_profile, :draft, seller_profile: seller_profile) }
        let(:Authorization) { bearer_for(user) }
        let(:id) { legal_profile.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["verification_status"]).to eq("pending_review")
        end
      end
    end
  end

  path "/api/v1/legal_profiles/{id}/approve" do
    post "Подтверждение верификации юридического профиля" do
      tags "Legal profiles"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          comment: { type: :string, example: "Документы проверены" }
        }
      }

      response "200", "Юридический профиль одобрен" do
        let(:admin) { create(:user, role: :supermanager) }
        let(:Authorization) { bearer_for(admin) }
        let(:seller) { create(:user, role: :seller) }
        let!(:seller_profile) { create(:seller_profile, user: seller) }
        let!(:legal_profile) { create(:legal_profile, :pending_review, seller_profile: seller_profile) }
        let(:id) { legal_profile.id }
        let(:payload) { { comment: "Документы проверены" } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["verification_status"]).to eq("approved")
        end
      end
    end
  end

  path "/api/v1/legal_profiles/{id}/reject" do
    post "Отклонение юридического профиля" do
      tags "Legal profiles"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          comment: { type: :string, example: "Нужно уточнить регистрационные данные" }
        }
      }

      response "200", "Юридический профиль отклонён" do
        let(:admin) { create(:user, role: :superadmin) }
        let(:Authorization) { bearer_for(admin) }
        let(:seller) { create(:user, role: :seller) }
        let!(:seller_profile) { create(:seller_profile, user: seller) }
        let!(:legal_profile) { create(:legal_profile, :pending_review, seller_profile: seller_profile) }
        let(:id) { legal_profile.id }
        let(:payload) { { comment: "Нужно уточнить регистрационные данные" } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["verification_status"]).to eq("rejected")
        end
      end
    end
  end

  path "/api/v1/legal_profiles/{id}/verification_events" do
    get "История верификации юридического профиля" do
      tags "Legal profiles"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "История событий верификации" do
        let(:user) { create(:user, role: :seller) }
        let!(:seller_profile) { create(:seller_profile, user: user) }
        let!(:legal_profile) { create(:legal_profile, :pending_review, seller_profile: seller_profile) }
        let(:Authorization) { bearer_for(user) }
        let(:id) { legal_profile.id }

        before do
          legal_profile.record_verification_event!(
            event_type: :submitted,
            actor_user: user,
            from_status: :draft,
            to_status: :pending_review
          )
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.first["event_type"]).to eq("submitted")
        end
      end
    end
  end

  path "/api/v1/seller_onboarding" do
    post "Первичный онбординг продавца" do
      tags "Seller onboarding"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          seller_profile: {
            type: :object,
            properties: {
              display_name: { type: :string, example: "Miras Store Group" },
              description: { type: :string, example: "Описание продавца" },
              logo_url: { type: :string, example: "https://cdn.example.com/logo.png" }
            },
            required: %w[display_name]
          },
          legal_profile: {
            type: :object,
            properties: {
              country_code: { type: :string, example: "KZ" },
              legal_form_code: { type: :string, example: "limited_liability_partnership" },
              legal_name: { type: :string, example: "TOO Miras Trade" },
              registration_number_type: { type: :string, example: "bin" },
              registration_number: { type: :string, example: "123456789012" },
              legal_address: { type: :string, example: "Алматы, Абая 1" }
            },
            required: %w[country_code legal_form_code legal_name registration_number_type registration_number]
          },
          shop: {
            type: :object,
            properties: {
              title: { type: :string, example: "Miras Flowers" },
              slug: { type: :string, example: "miras-flowers" },
              description: { type: :string, example: "Магазин цветов с доставкой" },
              logo_url: { type: :string, example: "https://cdn.example.com/shops/miras-flowers.png" },
              contact_phone: { type: :string, example: "+77001234567" },
              contact_email: { type: :string, example: "shop@example.com" },
              physical_address: { type: :string, example: "Алматы, Байзакова 10" },
              shop_type: { type: :string, example: "online" },
              shop_category_id: { type: :integer, example: 1 }
            },
            required: %w[title slug contact_phone shop_type shop_category_id]
          }
        },
        required: %w[seller_profile legal_profile shop]
      }

      response "201", "Онбординг продавца выполнен" do
        let(:user) { create(:user, role: :user) }
        let(:Authorization) { bearer_for(user) }
        let(:payload) do
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

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.dig("seller_profile", "slug")).to eq("miras-store-group")
          expect(json.dig("legal_profile", "verification_status")).to eq("draft")
        end
      end
    end
  end

  path "/api/v1/public/legal_profiles/{id}/transparency" do
    get "Публичная прозрачность продавца и юридического профиля" do
      tags "Public legal profiles"
      produces "application/json"
      security []
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "Публичные безопасные данные по продавцу" do
        let(:seller) { create(:user, role: :seller) }
        let!(:seller_profile) { create(:seller_profile, user: seller, display_name: "Miras Group") }
        let!(:legal_profile) { create(:legal_profile, seller_profile: seller_profile, verification_status: :approved) }
        let!(:shop) { create(:shop, seller_profile: seller_profile, legal_profile: legal_profile, title: "Miras Flowers") }
        let(:Authorization) { nil }
        let(:id) { legal_profile.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.dig("seller", "display_name")).to eq("Miras Group")
          expect(json.dig("legal_profile", "registration_number_public")).to eq(legal_profile.registration_number)
          expect(json["related_shops"].first["slug"]).to eq(shop.slug)
        end
      end
    end
  end
end
