require "rails_helper"

RSpec.describe "Api::V1::SellerProfiles", type: :request do
  describe "POST /api/v1/seller_profiles" do
    let(:user) { create(:user, role: :user) }

    it "creates seller profile and upgrades the user role to seller" do
      post "/api/v1/seller_profiles",
           headers: auth_headers(user),
           params: {
             display_name: "Miras Store Group",
             description: "Seller description",
             logo_url: "https://cdn.example.com/logo.png"
           }

      expect(response).to have_http_status(:created)
      expect(json_body["display_name"]).to eq("Miras Store Group")
      expect(json_body["slug"]).to eq("miras-store-group")
      expect(user.reload.role).to eq("seller")
    end

    it "returns 422 when seller profile already exists" do
      create(:seller_profile, user: user)

      post "/api/v1/seller_profiles",
           headers: auth_headers(user),
           params: { display_name: "Another Seller" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "key")).to eq("seller_profiles.already_exists")
    end
  end

  describe "PATCH /api/v1/seller_profiles/:id" do
    let(:user) { create(:user, role: :seller) }
    let(:seller_profile) { create(:seller_profile, user: user, display_name: "Miras Brand") }

    it "does not allow changing slug through update params" do
      original_slug = seller_profile.slug

      patch "/api/v1/seller_profiles/#{seller_profile.id}",
            headers: auth_headers(user),
            params: {
              display_name: "Updated Brand",
              slug: "hacked-slug"
            }

      expect(response).to have_http_status(:ok)
      expect(json_body["display_name"]).to eq("Updated Brand")
      expect(json_body["slug"]).to eq(original_slug)
      expect(seller_profile.reload.slug).to eq(original_slug)
    end
  end
end
