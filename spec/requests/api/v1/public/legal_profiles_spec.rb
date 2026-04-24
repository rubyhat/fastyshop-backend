require "rails_helper"

RSpec.describe "Api::V1::Public::LegalProfiles", type: :request do
  describe "GET /api/v1/public/legal_profiles/:id/transparency" do
    it "returns safe public transparency data for BIN profile" do
      seller = create(:user, role: :seller)
      seller_profile = create(:seller_profile, user: seller, display_name: "Miras Group", description: "Trusted seller")
      legal_profile = create(:legal_profile, seller_profile: seller_profile, verification_status: :approved)
      active_shop = create(:shop, seller_profile: seller_profile, legal_profile: legal_profile, title: "Active Shop")
      create(:shop, seller_profile: seller_profile, legal_profile: legal_profile, title: "Inactive Shop", status: :disabled_by_owner)

      get "/api/v1/public/legal_profiles/#{legal_profile.id}/transparency"

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("seller", "display_name")).to eq("Miras Group")
      expect(json_body.dig("legal_profile", "registration_number_public")).to eq(legal_profile.registration_number)
      expect(json_body.dig("legal_profile", "verification_status")).to eq("approved")
      expect(json_body.dig("legal_profile", "legal_address")).to be_nil
      expect(json_body.dig("seller", "user_id")).to be_nil
      expect(json_body["related_shops"].size).to eq(1)
      expect(json_body["related_shops"].first["slug"]).to eq(active_shop.slug)
      expect(json_body["related_shops"].first["verified_badge"]).to be(true)
    end

    it "does not expose IIN publicly" do
      seller = create(:user, role: :seller)
      seller_profile = create(:seller_profile, user: seller)
      legal_profile = create(:legal_profile, :individual_entrepreneur, seller_profile: seller_profile, verification_status: :approved)

      get "/api/v1/public/legal_profiles/#{legal_profile.id}/transparency"

      expect(response).to have_http_status(:ok)
      expect(json_body.dig("legal_profile", "registration_number_type")).to eq("iin")
      expect(json_body.dig("legal_profile", "registration_number_public")).to be_nil
      expect(response.body).not_to include(legal_profile.registration_number)
    end
  end
end
