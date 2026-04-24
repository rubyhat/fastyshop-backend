# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Order core API", swagger_doc: "v1/swagger.yaml", type: :request do
  def bearer_for(user)
    "Bearer #{JwtService.generate_tokens(user)[:access_token]}"
  end

  let(:buyer) { create(:user) }
  let(:seller) { create(:user, role: :seller) }
  let!(:seller_profile) { create(:seller_profile, user: seller) }
  let!(:shop) { create(:shop, seller_profile: seller_profile, status: :active) }

  path "/api/v1/carts/{shop_id}" do
    get "Корзина пользователя по магазину" do
      tags "Cart"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }

      response "200", "Корзина с price_changed и unavailable items" do
        let(:Authorization) { bearer_for(buyer) }
        let(:shop_id) { shop.id }
        let!(:price_changed_product) { create(:product, shop: shop, price: 1000, stock_quantity: 3) }
        let!(:unavailable_product) { create(:product, shop: shop, price: 700, stock_quantity: 3) }
        let!(:cart) { create(:cart, user: buyer, shop: shop) }
        let!(:cart_item_changed) { create(:cart_item, cart: cart, product: price_changed_product, quantity: 1, price_snapshot: 800) }
        let!(:cart_item_unavailable) { create(:cart_item, cart: cart, product: unavailable_product, quantity: 1, price_snapshot: 700) }

        before do
          price_changed_product.update!(price: 1200)
          unavailable_product.update_columns(status: Product.statuses.fetch("archived"), archived_at: Time.current)
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("active")
          expect(json["items"].size).to eq(2)
        end
      end
    end
  end

  path "/api/v1/orders/from_cart/{shop_id}" do
    post "Оформление заказа из корзины" do
      tags "Orders"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :"Idempotency-Key", in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          order: {
            type: :object,
            properties: {
              contact_name: { type: :string, nullable: true, example: "Алия Омарова" },
              contact_phone: { type: :string, nullable: true, example: "+77001234567" },
              customer_comment: { type: :string, nullable: true, example: "Позвоните перед подтверждением" }
            }
          }
        }
      }

      response "201", "Заказ создан из валидных товаров, skipped items остаются в корзине" do
        let(:Authorization) { bearer_for(buyer) }
        let(:"Idempotency-Key") { "swagger-checkout-1" }
        let(:shop_id) { shop.id }
        let!(:valid_product) { create(:product, shop: shop, title: "Valid", stock_quantity: 3, price: 1500) }
        let!(:skipped_product) { create(:product, shop: shop, title: "Skipped", stock_quantity: 1, price: 900) }
        let!(:cart) { create(:cart, user: buyer, shop: shop) }
        let!(:valid_cart_item) { create(:cart_item, cart: cart, product: valid_product, quantity: 1, price_snapshot: 1000) }
        let!(:skipped_cart_item) { create(:cart_item, cart: cart, product: skipped_product, quantity: 1, price_snapshot: 900) }
        let(:payload) { { order: { customer_comment: "Позвоните перед подтверждением" } } }

        before do
          skipped_product.update!(stock_quantity: 0)
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.dig("order", "status")).to eq("created")
          expect(json.dig("checkout_summary", "ordered_items").size).to eq(1)
          expect(json.dig("checkout_summary", "skipped_items").size).to eq(1)
        end
      end
    end
  end

  path "/api/v1/my/orders" do
    get "Список заказов покупателя" do
      tags "Orders"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :status, in: :query, required: false, schema: {
        type: :string,
        enum: %w[created accepted in_progress ready completed rejected_by_seller canceled_by_user canceled_by_seller]
      }

      response "200", "Список собственных заказов buyer" do
        let(:Authorization) { bearer_for(buyer) }
        let(:status) { "created" }
        let!(:own_order) { create(:order, user: buyer, shop: shop, status: :created) }
        let!(:other_order) { create(:order, user: create(:user), shop: shop, status: :created) }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.pluck("id")).to eq([ own_order.id ])
        end
      end
    end
  end

  path "/api/v1/shops/{shop_id}/orders" do
    get "Список заказов магазина для продавца" do
      tags "Orders"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :status, in: :query, required: false, schema: {
        type: :string,
        enum: %w[created accepted in_progress ready completed rejected_by_seller canceled_by_user canceled_by_seller]
      }

      response "200", "Список заказов только по выбранному магазину" do
        let(:Authorization) { bearer_for(seller) }
        let(:shop_id) { shop.id }
        let(:status) { nil }
        let!(:own_order) { create(:order, user: buyer, shop: shop, status: :created) }
        let!(:other_order) { create(:order, user: buyer, shop: create(:shop), status: :created) }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.pluck("id")).to eq([ own_order.id ])
        end
      end
    end
  end

  path "/api/v1/orders/{id}/status" do
    patch "Смена статуса заказа" do
      tags "Orders"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          order: {
            type: :object,
            properties: {
              status: { type: :string, enum: %w[accepted rejected_by_seller canceled_by_user canceled_by_seller in_progress ready completed] },
              comment: { type: :string, nullable: true, example: "Товар закончился" }
            },
            required: %w[status]
          }
        },
        required: %w[order]
      }

      response "200", "Заказ переведён в rejected_by_seller и stock восстановлен" do
        let(:Authorization) { bearer_for(seller) }
        let!(:product) { create(:product, shop: shop, stock_quantity: 1) }
        let!(:order) { create(:order, user: buyer, shop: shop, status: :created, inventory_restored_at: nil) }
        let!(:order_item) { create(:order_item, order: order, product: product, quantity: 1) }
        let(:id) { order.id }
        let(:payload) { { order: { status: "rejected_by_seller", comment: "Товар закончился" } } }

        before do
          order.record_event!(event_type: :created, actor_user: buyer, from_status: nil, to_status: :created)
          product.decrement!(:stock_quantity, 1)
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("rejected_by_seller")
          expect(json["last_public_comment"]).to eq("Товар закончился")
        end
      end
    end
  end

  path "/api/v1/orders/{id}/events" do
    get "История событий заказа" do
      tags "Orders"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :id, in: :path, schema: { type: :string }

      response "200", "Timeline заказа" do
        let(:Authorization) { bearer_for(buyer) }
        let!(:order) { create(:order, user: buyer, shop: shop, status: :rejected_by_seller) }
        let(:id) { order.id }

        before do
          order.record_event!(event_type: :created, actor_user: buyer, from_status: nil, to_status: :created)
          order.record_event!(event_type: :rejected_by_seller, actor_user: seller, from_status: :created, to_status: :rejected_by_seller, comment: "Товар закончился")
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.map { |row| row["event_type"] }).to eq(%w[created rejected_by_seller])
        end
      end
    end
  end

  path "/api/v1/shops/{shop_id}/customers" do
    get "Список покупателей магазина" do
      tags "Shop customers"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }

      response "200", "Read-only customer base продавца" do
        let(:Authorization) { bearer_for(seller) }
        let(:shop_id) { shop.id }
        let!(:own_order) { create(:order, user: buyer, shop: shop, status: :completed, total_price: 2500) }
        let!(:other_order) { create(:order, user: buyer, shop: create(:shop), status: :completed, total_price: 7000) }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json.size).to eq(1)
          expect(json.first["user_id"]).to eq(buyer.id)
        end
      end
    end
  end

  path "/api/v1/shops/{shop_id}/customers/{user_id}" do
    get "Детальная карточка покупателя магазина" do
      tags "Shop customers"
      produces "application/json"
      security [ Bearer: [] ]
      parameter name: :Authorization, in: :header, schema: { type: :string }
      parameter name: :shop_id, in: :path, schema: { type: :string }
      parameter name: :user_id, in: :path, schema: { type: :string }

      response "200", "Покупатель и его заказы только в рамках магазина" do
        let(:Authorization) { bearer_for(seller) }
        let(:shop_id) { shop.id }
        let!(:own_order) { create(:order, user: buyer, shop: shop, status: :completed, total_price: 2500) }
        let!(:other_order) { create(:order, user: buyer, shop: create(:shop), status: :completed, total_price: 7000) }
        let(:user_id) { buyer.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["user_id"]).to eq(buyer.id)
          expect(json["orders"].pluck("id")).to eq([ own_order.id ])
        end
      end
    end
  end
end
