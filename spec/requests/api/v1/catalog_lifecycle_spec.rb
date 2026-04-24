require "rails_helper"

RSpec.describe "Api::V1::CatalogLifecycle", type: :request do
  let(:seller) { create(:user, role: :seller) }
  let(:seller_profile) { create(:seller_profile, user: seller) }
  let(:shop) { create(:shop, seller_profile: seller_profile) }

  describe "private category lifecycle" do
    it "creates, publishes, previews archive and archives category cascade" do
      post "/api/v1/shops/#{shop.id}/product_categories",
           headers: auth_headers(seller),
           params: { product_category: { title: "Flowers" } }

      expect(response).to have_http_status(:created)
      category_id = json_body["id"]
      expect(json_body["status"]).to eq("draft")

      post "/api/v1/shops/#{shop.id}/product_categories/#{category_id}/publish", headers: auth_headers(seller)

      expect(response).to have_http_status(:ok)
      expect(json_body["status"]).to eq("published")

      child = create(:product_category, shop: shop, parent_id: category_id)
      create(:product, shop: shop, product_category: child)

      post "/api/v1/shops/#{shop.id}/product_categories/#{category_id}/archive_preview", headers: auth_headers(seller)

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("affected", "child_categories_count")).to eq(1)
      expect(json_body.dig("affected", "products_count")).to eq(1)

      post "/api/v1/shops/#{shop.id}/product_categories/#{category_id}/archive", headers: auth_headers(seller)

      expect(response).to have_http_status(:ok)
      expect(json_body["status"]).to eq("archived")
      expect(child.reload).to be_archived
    end

    it "allows owner to edit category while shop is suspended by admin" do
      shop.update!(status: :suspended_by_admin, status_comment: "Исправьте контент")
      category = create(:product_category, shop: shop)

      patch "/api/v1/shops/#{shop.id}/product_categories/#{category.id}",
            headers: auth_headers(seller),
            params: { product_category: { title: "Updated" } }

      expect(response).to have_http_status(:ok)
      expect(json_body["title"]).to eq("Updated")
    end
  end

  describe "private product lifecycle" do
    it "creates product without category and publishes it" do
      post "/api/v1/shops/#{shop.id}/products",
           headers: auth_headers(seller),
           params: {
             product: {
               title: "Simple product",
               price: "1000.00",
               product_type: "physical",
               stock_quantity: 3
             }
           }

      expect(response).to have_http_status(:created)
      product_id = json_body["id"]
      expect(json_body["product_category_id"]).to be_nil
      expect(json_body["status"]).to eq("draft")

      post "/api/v1/shops/#{shop.id}/products/#{product_id}/publish", headers: auth_headers(seller)

      expect(response).to have_http_status(:ok)
      expect(json_body["status"]).to eq("published")
    end

    it "forbids another seller from updating product" do
      other_seller = create(:user, role: :seller)
      create(:seller_profile, user: other_seller)
      product = create(:product, shop: shop)

      patch "/api/v1/shops/#{shop.id}/products/#{product.id}",
            headers: auth_headers(other_seller),
            params: { product: { title: "Hacked" } }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
