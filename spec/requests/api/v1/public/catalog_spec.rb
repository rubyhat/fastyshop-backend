require "rails_helper"

RSpec.describe "Api::V1::Public::Catalog", type: :request do
  describe "GET /api/v1/public/shops/:shop_slug/categories" do
    it "returns only published categories for active shop" do
      shop = create(:shop, slug: "public-catalog")
      published_category = create(:product_category, shop: shop, title: "Published")
      create(:product_category, :draft, shop: shop, title: "Draft")

      get "/api/v1/public/shops/#{shop.slug}/categories"

      expect(response).to have_http_status(:ok)
      expect(json_body.pluck("slug")).to contain_exactly(published_category.slug)
    end
  end

  describe "GET /api/v1/public/shops/:shop_slug/products" do
    it "returns published products including uncategorized products" do
      shop = create(:shop, slug: "public-products")
      product = create(:product, :without_category, shop: shop, title: "Uncategorized")
      create(:product, :draft, :without_category, shop: shop, title: "Draft")

      get "/api/v1/public/shops/#{shop.slug}/products"

      expect(response).to have_http_status(:ok)
      expect(json_body.pluck("slug")).to contain_exactly(product.slug)
      expect(json_body.first["category"]).to be_nil
    end

    it "filters products by published category slug including descendants" do
      shop = create(:shop, slug: "category-filter")
      category = create(:product_category, shop: shop, title: "Parent")
      child_category = create(:product_category, shop: shop, parent: category, title: "Child")
      child_product = create(:product, shop: shop, product_category: child_category, title: "Child Product")
      create(:product, :without_category, shop: shop, title: "Uncategorized")

      get "/api/v1/public/shops/#{shop.slug}/products", params: { category_slug: category.slug }

      expect(response).to have_http_status(:ok)
      expect(json_body.pluck("slug")).to contain_exactly(child_product.slug)
    end

    it "does not return content for suspended shop" do
      shop = create(:shop, slug: "suspended-products", status: :suspended_by_admin)
      create(:product, :without_category, shop: shop)

      get "/api/v1/public/shops/#{shop.slug}/products"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/public/shops/:shop_slug/products/:product_slug" do
    it "returns product details by slug" do
      shop = create(:shop, slug: "product-detail")
      product = create(:product, shop: shop, title: "Detail Product")

      get "/api/v1/public/shops/#{shop.slug}/products/#{product.slug}"

      expect(response).to have_http_status(:ok)
      expect(json_body["slug"]).to eq(product.slug)
      expect(json_body["availability"]).to eq("available")
    end

    it "does not expose draft product details" do
      shop = create(:shop, slug: "draft-product-detail")
      product = create(:product, :draft, :without_category, shop: shop, title: "Hidden Product")

      get "/api/v1/public/shops/#{shop.slug}/products/#{product.slug}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
