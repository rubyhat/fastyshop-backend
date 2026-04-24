require "rails_helper"

RSpec.describe "Api::V1::CartOrderCore", type: :request do
  let(:buyer) { create(:user) }
  let(:seller) { create(:user, role: :seller) }
  let!(:seller_profile) { create(:seller_profile, user: seller) }
  let!(:shop) { create(:shop, seller_profile: seller_profile, status: :active) }

  describe "GET /api/v1/carts/:shop_id" do
    it "returns price_changed and unavailable items" do
      price_changed_product = create(:product, shop: shop, price: 1000, stock_quantity: 3)
      unavailable_product = create(:product, shop: shop, price: 700, stock_quantity: 3)
      cart = create(:cart, user: buyer, shop: shop)
      create(:cart_item, cart: cart, product: price_changed_product, quantity: 1, price_snapshot: 800)
      create(:cart_item, cart: cart, product: unavailable_product, quantity: 1, price_snapshot: 700)

      price_changed_product.update!(price: 1200)
      unavailable_product.update_columns(status: Product.statuses.fetch("archived"), archived_at: Time.current)

      get "/api/v1/carts/#{shop.id}", headers: auth_headers(buyer)

      expect(response).to have_http_status(:ok)
      expect(json_body["status"]).to eq("active")

      items_by_product_id = json_body["items"].index_by { |item| item["product_id"] }
      changed_item = items_by_product_id.fetch(price_changed_product.id)
      unavailable_item = items_by_product_id.fetch(unavailable_product.id)

      expect(changed_item["price_changed"]).to eq(true)
      expect(BigDecimal(changed_item["current_price"])).to eq(price_changed_product.price)

      expect(unavailable_item["availability"]).to eq("unavailable")
      expect(unavailable_item.dig("unavailable_reason", "key")).to eq("cart.item.product_unavailable")
      expect(unavailable_item.dig("product", "status")).to eq("archived")
    end
  end

  describe "POST /api/v1/carts/:shop_id/add" do
    it "does not allow adding product from another shop" do
      other_shop = create(:shop)
      product = create(:product, shop: other_shop)

      post "/api/v1/carts/#{shop.id}/add",
           headers: auth_headers(buyer),
           params: { cart: { product_id: product.id, quantity: 1 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "key")).to eq("cart.add_item_error")
    end

    it "does not allow adding unavailable product" do
      product = create(:product, shop: shop, stock_quantity: 0)

      post "/api/v1/carts/#{shop.id}/add",
           headers: auth_headers(buyer),
           params: { cart: { product_id: product.id, quantity: 1 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "key")).to eq("cart.product_unavailable")
    end
  end

  describe "POST /api/v1/orders/from_cart/:shop_id" do
    it "creates order for valid items, keeps skipped items in cart and returns checkout summary" do
      valid_product = create(:product, shop: shop, title: "Valid", stock_quantity: 3, price: 1500)
      skipped_product = create(:product, shop: shop, title: "Skipped", stock_quantity: 1, price: 900)
      cart = create(:cart, user: buyer, shop: shop)
      create(:cart_item, cart: cart, product: valid_product, quantity: 1, price_snapshot: 1000)
      create(:cart_item, cart: cart, product: skipped_product, quantity: 1, price_snapshot: 900)
      skipped_product.update!(stock_quantity: 0)

      post "/api/v1/orders/from_cart/#{shop.id}",
           headers: auth_headers(buyer).merge("Idempotency-Key" => "checkout-req-1"),
           params: { order: { customer_comment: "Позвоните перед подтверждением" } }

      expect(response).to have_http_status(:created)
      expect(json_body.dig("order", "status")).to eq("created")
      expect(json_body.dig("order", "customer_comment")).to eq("Позвоните перед подтверждением")
      expect(json_body.dig("checkout_summary", "ordered_items").size).to eq(1)
      expect(json_body.dig("checkout_summary", "skipped_items").size).to eq(1)
      expect(json_body.dig("checkout_summary", "price_changed_items").size).to eq(1)
      expect(json_body.dig("cart", "status")).to eq("active")
      expect(json_body.dig("cart", "items_count")).to eq(1)

      expect(cart.reload.cart_items.pluck(:product_id)).to contain_exactly(skipped_product.id)
      expect(valid_product.reload.stock_quantity).to eq(2)
      expect(Order.count).to eq(1)
    end

    it "does not create duplicate order for the same idempotency key" do
      product = create(:product, shop: shop, stock_quantity: 3, price: 1000)
      cart = create(:cart, user: buyer, shop: shop)
      create(:cart_item, cart: cart, product: product, quantity: 1)
      headers = auth_headers(buyer).merge("Idempotency-Key" => "checkout-req-2")

      post "/api/v1/orders/from_cart/#{shop.id}", headers: headers, params: { order: {} }
      first_order_id = json_body.dig("order", "id")

      post "/api/v1/orders/from_cart/#{shop.id}", headers: headers, params: { order: {} }

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("order", "id")).to eq(first_order_id)
      expect(Order.count).to eq(1)
    end

    it "does not create order when only invalid items remain in cart" do
      unavailable_product = create(:product, shop: shop, stock_quantity: 1, price: 1000)
      cart = create(:cart, user: buyer, shop: shop)
      create(:cart_item, cart: cart, product: unavailable_product, quantity: 1)
      unavailable_product.update!(stock_quantity: 0)

      post "/api/v1/orders/from_cart/#{shop.id}",
           headers: auth_headers(buyer).merge("Idempotency-Key" => "checkout-req-3"),
           params: { order: {} }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "key")).to eq("order.no_valid_items")
      expect(Order.count).to eq(0)
      expect(cart.reload).to be_active
      expect(cart.cart_items.count).to eq(1)
    end
  end

  describe "order listing and visibility" do
    it "returns only buyer orders in my orders list" do
      own_order = create(:order, user: buyer, shop: shop, status: :created)
      create(:order, user: create(:user), shop: shop, status: :created)

      get "/api/v1/my/orders", headers: auth_headers(buyer)

      expect(response).to have_http_status(:ok)
      expect(json_body.map { |row| row["id"] }).to contain_exactly(own_order.id)
    end

    it "returns only seller shop orders in shop orders list" do
      own_order = create(:order, user: buyer, shop: shop, status: :created)
      other_shop = create(:shop)
      create(:order, user: buyer, shop: other_shop, status: :created)

      get "/api/v1/shops/#{shop.id}/orders", headers: auth_headers(seller)

      expect(response).to have_http_status(:ok)
      expect(json_body.map { |row| row["id"] }).to contain_exactly(own_order.id)
    end
  end

  describe "PATCH /api/v1/orders/:id/status and GET /api/v1/orders/:id/events" do
    it "rejects order with comment, restores stock and returns order timeline" do
      product = create(:product, shop: shop, stock_quantity: 1)
      order = create(:order, user: buyer, shop: shop, status: :created, inventory_restored_at: nil)
      create(:order_item, order: order, product: product, quantity: 1)
      order.record_event!(event_type: :created, actor_user: buyer, from_status: nil, to_status: :created)
      product.decrement!(:stock_quantity, 1)

      patch "/api/v1/orders/#{order.id}/status",
            headers: auth_headers(seller),
            params: { order: { status: "rejected_by_seller", comment: "Товар закончился" } }

      expect(response).to have_http_status(:ok)
      expect(json_body["status"]).to eq("rejected_by_seller")
      expect(json_body["last_public_comment"]).to eq("Товар закончился")
      expect(json_body["inventory_restored_at"]).to be_present
      expect(product.reload.stock_quantity).to eq(1)

      get "/api/v1/orders/#{order.id}/events", headers: auth_headers(buyer)

      expect(response).to have_http_status(:ok)
      expect(json_body.map { |row| row["event_type"] }).to eq(%w[created rejected_by_seller])
    end

    it "does not allow buyer to cancel accepted order" do
      order = create(:order, user: buyer, shop: shop, status: :accepted)

      patch "/api/v1/orders/#{order.id}/status",
            headers: auth_headers(buyer),
            params: { order: { status: "canceled_by_user", comment: "Передумал" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "key")).to eq("validation.failed")
      expect(json_body.dig("error", "details", "base")).to include("У вас нет прав на это изменение статуса")
    end
  end

  describe "seller customer base" do
    it "returns shop customers list and detail without leaking other shop orders" do
      own_order = create(:order, user: buyer, shop: shop, status: :completed, total_price: 2500)
      other_shop = create(:shop)
      create(:order, user: buyer, shop: other_shop, status: :completed, total_price: 7000)

      get "/api/v1/shops/#{shop.id}/customers", headers: auth_headers(seller)

      expect(response).to have_http_status(:ok)
      expect(json_body.size).to eq(1)
      expect(json_body.first["user_id"]).to eq(buyer.id)
      expect(json_body.first["orders_count"]).to eq(1)
      expect(BigDecimal(json_body.first["total_spent"])).to eq(BigDecimal("2500"))

      get "/api/v1/shops/#{shop.id}/customers/#{buyer.id}", headers: auth_headers(seller)

      expect(response).to have_http_status(:ok)
      expect(json_body["user_id"]).to eq(buyer.id)
      expect(json_body["orders"].map { |row| row["id"] }).to contain_exactly(own_order.id)
    end
  end
end
