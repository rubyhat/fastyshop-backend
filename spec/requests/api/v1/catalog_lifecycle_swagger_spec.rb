# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Catalog lifecycle API", swagger_doc: "v1/swagger.yaml", type: :request do
  def bearer_for(user)
    "Bearer #{JwtService.generate_tokens(user)[:access_token]}"
  end

  let(:seller) { create(:user, role: :seller) }
  let!(:seller_profile) { create(:seller_profile, user: seller) }
  let!(:shop) { create(:shop, seller_profile: seller_profile, status: :active) }
  let(:Authorization) { bearer_for(seller) }
  let(:shop_id) { shop.id }

  path "/api/v1/shops/{shop_id}/product_categories" do
    get "Список категорий магазина для кабинета" do
      tags "Product categories"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :status, in: :query, required: false, schema: {
        type: :string,
        enum: %w[draft published archived]
      }

      response "200", "Категории магазина" do
        let(:status) { "published" }
        let!(:category) { create(:product_category, shop: shop, title: "Published category") }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.pluck("id")).to include(category.id)
        end
      end
    end

    post "Создание категории магазина в статусе draft" do
      tags "Product categories"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          product_category: {
            type: :object,
            properties: {
              title: { type: :string, example: "Цветы" },
              parent_id: { type: :string, nullable: true, example: nil },
              position: { type: :integer, example: 1 }
            },
            required: %w[title]
          }
        },
        required: %w[product_category]
      }

      response "201", "Категория создана" do
        let(:payload) { { product_category: { title: "Цветы" } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("draft")
        end
      end
    end
  end

  path "/api/v1/shops/{shop_id}/product_categories/{id}/publish" do
    post "Публикация категории" do
      tags "Product categories"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "Категория опубликована" do
        let!(:category) { create(:product_category, :draft, shop: shop, title: "Draft category") }
        let(:id) { category.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("published")
        end
      end
    end
  end

  path "/api/v1/shops/{shop_id}/product_categories/{id}/archive_preview" do
    post "Предпросмотр архивирования категории" do
      tags "Product categories"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "Количество затронутых сущностей" do
        let!(:category) { create(:product_category, shop: shop, title: "Root category") }
        let!(:child_category) { create(:product_category, shop: shop, parent: category, title: "Child category") }
        let!(:product) { create(:product, shop: shop, product_category: child_category) }
        let(:id) { category.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.dig("affected", "child_categories_count")).to eq(1)
          expect(json.dig("affected", "products_count")).to eq(1)
        end
      end
    end
  end

  path "/api/v1/shops/{shop_id}/product_categories/{id}/archive" do
    post "Архивирование категории с каскадом по потомкам" do
      tags "Product categories"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "Категория архивирована" do
        let!(:category) { create(:product_category, shop: shop, title: "Archive root") }
        let!(:child_category) { create(:product_category, shop: shop, parent: category, title: "Archive child") }
        let!(:product) { create(:product, shop: shop, product_category: child_category) }
        let(:id) { category.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("archived")
          expect(product.reload).to be_archived
        end
      end
    end
  end

  path "/api/v1/shops/{shop_id}/product_categories/{id}/restore" do
    post "Восстановление категории в draft" do
      tags "Product categories"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "Категория восстановлена в draft" do
        let!(:category) { create(:product_category, :archived, shop: shop, title: "Archived category") }
        let(:id) { category.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("draft")
        end
      end
    end
  end

  path "/api/v1/shops/{shop_id}/products" do
    get "Список товаров магазина для кабинета" do
      tags "Products"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :status, in: :query, required: false, schema: {
        type: :string,
        enum: %w[draft published archived]
      }

      response "200", "Товары магазина" do
        let(:status) { "published" }
        let!(:product) { create(:product, :without_category, shop: shop, title: "Published product") }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.pluck("id")).to include(product.id)
        end
      end
    end

    post "Создание товара магазина в статусе draft" do
      tags "Products"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          product: {
            type: :object,
            properties: {
              title: { type: :string, example: "Букет тюльпанов" },
              description: { type: :string, example: "Весенний букет" },
              price: { type: :string, example: "15000.00" },
              product_type: { type: :string, enum: %w[physical digital service], example: "physical" },
              product_category_id: { type: :string, nullable: true, example: nil },
              stock_quantity: { type: :integer, example: 5 },
              sku: { type: :string, nullable: true, example: "FLOWER-001" },
              image_url: { type: :string, nullable: true, example: nil }
            },
            required: %w[title price product_type]
          }
        },
        required: %w[product]
      }

      response "201", "Товар создан" do
        let(:payload) do
          {
            product: {
              title: "Букет тюльпанов",
              price: "15000.00",
              product_type: "physical",
              stock_quantity: 5
            }
          }
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("draft")
        end
      end
    end
  end

  path "/api/v1/shops/{shop_id}/products/{id}/publish" do
    post "Публикация товара" do
      tags "Products"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "Товар опубликован" do
        let!(:product) { create(:product, :draft, :without_category, shop: shop, title: "Draft product") }
        let(:id) { product.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("published")
        end
      end
    end
  end

  path "/api/v1/shops/{shop_id}/products/{id}/archive" do
    post "Архивирование товара" do
      tags "Products"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "Товар архивирован" do
        let!(:product) { create(:product, :without_category, shop: shop, title: "Published product") }
        let(:id) { product.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("archived")
        end
      end
    end
  end

  path "/api/v1/shops/{shop_id}/products/{id}/restore" do
    post "Восстановление товара в draft" do
      tags "Products"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "Товар восстановлен в draft" do
        let!(:product) { create(:product, :archived, :without_category, shop: shop, title: "Archived product") }
        let(:id) { product.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("draft")
        end
      end
    end
  end

  path "/api/v1/public/shops/{shop_slug}/categories" do
    get "Публичные опубликованные категории магазина" do
      tags "Public catalog"
      produces "application/json"
      security []
      parameter name: :shop_slug, in: :path, schema: { type: :string }

      response "200", "Опубликованные категории" do
        let!(:public_shop) { create(:shop, slug: "swagger-public-categories", status: :active) }
        let!(:category) { create(:product_category, shop: public_shop, title: "Public category") }
        let(:shop_slug) { public_shop.slug }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.pluck("slug")).to include(category.slug)
        end
      end
    end
  end

  path "/api/v1/public/shops/{shop_slug}/products" do
    get "Публичные опубликованные товары магазина" do
      tags "Public catalog"
      produces "application/json"
      security []
      parameter name: :shop_slug, in: :path, schema: { type: :string }
      parameter name: :category_slug, in: :query, required: false, schema: { type: :string }

      response "200", "Опубликованные товары" do
        let!(:public_shop) { create(:shop, slug: "swagger-public-products", status: :active) }
        let!(:category) { create(:product_category, shop: public_shop, title: "Catalog category") }
        let!(:product) { create(:product, shop: public_shop, product_category: category, title: "Public product") }
        let(:shop_slug) { public_shop.slug }
        let(:category_slug) { category.slug }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.pluck("slug")).to include(product.slug)
        end
      end
    end
  end

  path "/api/v1/public/shops/{shop_slug}/products/{product_slug}" do
    get "Публичная карточка опубликованного товара" do
      tags "Public catalog"
      produces "application/json"
      security []
      parameter name: :shop_slug, in: :path, schema: { type: :string }
      parameter name: :product_slug, in: :path, schema: { type: :string }

      response "200", "Опубликованный товар" do
        let!(:public_shop) { create(:shop, slug: "swagger-public-product-detail", status: :active) }
        let!(:product) { create(:product, :without_category, shop: public_shop, title: "Public detail product") }
        let(:shop_slug) { public_shop.slug }
        let(:product_slug) { product.slug }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["slug"]).to eq(product.slug)
          expect(json["availability"]).to eq("available")
        end
      end
    end
  end
end
