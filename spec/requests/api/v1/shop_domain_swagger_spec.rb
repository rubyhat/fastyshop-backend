require "swagger_helper"

RSpec.describe "Shop domain API", swagger_doc: "v1/swagger.yaml", type: :request do
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

  path "/api/v1/shops" do
    post "Создание магазина" do
      tags "Shops"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string, example: "Miras Flowers" },
          slug: { type: :string, example: "miras-flowers" },
          description: { type: :string, example: "Цветы с доставкой по Алматы" },
          logo_url: { type: :string, example: "https://cdn.example.com/shops/miras/logo.png" },
          contact_phone: { type: :string, example: "+77001234567" },
          contact_email: { type: :string, example: "shop@example.com" },
          physical_address: { type: :string, example: "Алматы, Байзакова 10" },
          shop_type: { type: :string, example: "hybrid" },
          shop_category_id: { type: :string, example: "uuid" },
          legal_profile_id: { type: :string, example: "uuid" }
        },
        required: %w[title slug contact_phone shop_type shop_category_id legal_profile_id]
      }

      response "201", "Магазин создан" do
        let(:seller) { create(:user, role: :seller) }
        let!(:seller_profile) { create(:seller_profile, user: seller) }
        let!(:legal_profile) { create(:legal_profile, seller_profile: seller_profile) }
        let(:Authorization) { bearer_for(seller) }
        let(:payload) do
          {
            title: "Miras Flowers",
            slug: "miras-flowers-swagger",
            description: "Цветы с доставкой по Алматы",
            logo_url: "https://cdn.example.com/shops/miras/logo.png",
            contact_phone: "+77001234567",
            contact_email: "shop@example.com",
            physical_address: "Алматы, Байзакова 10",
            shop_type: "hybrid",
            shop_category_id: shop_category.id,
            legal_profile_id: legal_profile.id
          }
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("active")
          expect(json["slug"]).to eq("miras-flowers-swagger")
        end
      end
    end
  end

  path "/api/v1/shops/{id}" do
    patch "Обновление магазина" do
      tags "Shops"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string, example: "Miras Flowers Premium" },
          slug: { type: :string, example: "miras-flowers-premium" },
          legal_profile_id: { type: :string, example: "uuid" }
        }
      }

      response "200", "Магазин обновлён" do
        let(:seller) { create(:user, role: :seller) }
        let!(:seller_profile) { create(:seller_profile, user: seller) }
        let!(:legal_profile) { create(:legal_profile, seller_profile: seller_profile) }
        let!(:shop) { create(:shop, seller_profile: seller_profile, legal_profile: legal_profile, slug: "old-swagger-shop") }
        let(:Authorization) { bearer_for(seller) }
        let(:id) { shop.id }
        let(:payload) { { title: "Miras Flowers Premium", slug: "new-swagger-shop" } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["slug"]).to eq("new-swagger-shop")
        end
      end
    end
  end

  path "/api/v1/shops/{id}/disable" do
    post "Отключение магазина владельцем" do
      tags "Shops"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "Магазин отключён владельцем" do
        let(:seller) { create(:user, role: :seller) }
        let!(:seller_profile) { create(:seller_profile, user: seller) }
        let!(:shop) { create(:shop, seller_profile: seller_profile, status: :active) }
        let(:Authorization) { bearer_for(seller) }
        let(:id) { shop.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("disabled_by_owner")
        end
      end
    end
  end

  path "/api/v1/shops/{id}/activate" do
    post "Активация магазина" do
      tags "Shops"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "Магазин активирован" do
        let(:seller) { create(:user, role: :seller) }
        let!(:seller_profile) { create(:seller_profile, user: seller) }
        let!(:shop) { create(:shop, seller_profile: seller_profile, status: :disabled_by_owner) }
        let(:Authorization) { bearer_for(seller) }
        let(:id) { shop.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("active")
        end
      end
    end
  end

  path "/api/v1/shops/{id}/suspend" do
    post "Отключение магазина платформой" do
      tags "Shops"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          comment: { type: :string, example: "Нарушение правил платформы" }
        },
        required: %w[comment]
      }

      response "200", "Магазин отключён платформой" do
        let(:admin) { create(:user, role: :superadmin) }
        let!(:shop) { create(:shop, status: :active) }
        let(:Authorization) { bearer_for(admin) }
        let(:id) { shop.id }
        let(:payload) { { comment: "Нарушение правил платформы" } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("suspended_by_admin")
        end
      end
    end
  end

  path "/api/v1/public/shops/catalog" do
    get "Публичный каталог магазинов" do
      tags "Public shops"
      produces "application/json"
      security []

      response "200", "Список активных магазинов" do
        let!(:shop) { create(:shop, slug: "public-catalog-shop", status: :active) }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.pluck("slug")).to include(shop.slug)
        end
      end
    end
  end

  path "/api/v1/public/shops/{slug}" do
    get "Публичная страница магазина" do
      tags "Public shops"
      produces "application/json"
      security []
      parameter name: :slug, in: :path, schema: { type: :string }

      response "200", "Публичные данные магазина" do
        let!(:shop) { create(:shop, slug: "public-shop-swagger", status: :active) }
        let(:slug) { shop.slug }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["canonical_slug"]).to eq("public-shop-swagger")
          expect(json["content_state"]).to eq("visible")
        end
      end
    end
  end

  path "/api/v1/public/shops/{slug}/legal_details" do
    get "Публичные юридические данные магазина" do
      tags "Public shops"
      produces "application/json"
      security []
      parameter name: :slug, in: :path, schema: { type: :string }

      response "200", "Юридическая прозрачность магазина" do
        let!(:shop) { create(:shop, slug: "legal-details-swagger", status: :active) }
        let(:slug) { shop.slug }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.dig("shop", "slug")).to eq("legal-details-swagger")
        end
      end
    end
  end

  path "/api/v1/public/shops/{slug}/change_history" do
    get "Публичная история trust-критичных изменений магазина" do
      tags "Public shops"
      produces "application/json"
      security []
      parameter name: :slug, in: :path, schema: { type: :string }

      response "200", "История изменений магазина" do
        let!(:shop) { create(:shop, slug: "history-swagger", status: :active) }
        let(:slug) { shop.slug }

        before do
          create(:shop_change_event, shop: shop, event_type: :title_changed, changeset: { from: "Old", to: "New" })
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.first["event_type"]).to eq("title_changed")
        end
      end
    end
  end
end
