require "rails_helper"

RSpec.describe "Api::V1::LegalProfiles", type: :request do
  let(:owner) { create(:user, role: :seller) }
  let(:seller_profile) { create(:seller_profile, user: owner) }

  let(:valid_params) do
    {
      country_code: "KZ",
      legal_form_code: "limited_liability_partnership",
      legal_name: "TOO Miras Trade",
      registration_number_type: "bin",
      registration_number: "123456789012",
      legal_address: "Алматы, Абая 1"
    }
  end

  describe "POST /api/v1/legal_profiles" do
    it "creates a draft legal profile for seller" do
      seller_profile

      post "/api/v1/legal_profiles", headers: auth_headers(owner), params: valid_params

      expect(response).to have_http_status(:created)
      expect(json_body["verification_status"]).to eq("draft")
      expect(json_body["legal_form_code"]).to eq("limited_liability_partnership")
      expect(json_body["registration_number_type"]).to eq("bin")
    end

    it "returns 403 when user has no seller profile" do
      post "/api/v1/legal_profiles", headers: auth_headers(owner), params: valid_params

      expect(response).to have_http_status(:forbidden)
      expect(json_body.dig("error", "key")).to eq("legal_profiles.no_seller_profile")
    end

    it "returns 422 for unsupported country" do
      seller_profile

      post "/api/v1/legal_profiles",
           headers: auth_headers(owner),
           params: valid_params.merge(country_code: "RU")

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "details", "country_code")).to include(a_string_including("страна временно не поддерживается для продавцов"))
    end

    it "returns 422 for invalid legal form and registration type pair" do
      seller_profile

      post "/api/v1/legal_profiles",
           headers: auth_headers(owner),
           params: valid_params.merge(registration_number_type: "iin")

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "details", "registration_number_type")).to include(a_string_including("не соответствует выбранной юридической форме"))
    end
  end

  describe "POST /api/v1/legal_profiles/:id/submit_verification" do
    let(:legal_profile) { create(:legal_profile, :draft, seller_profile: seller_profile) }

    it "moves profile from draft to pending_review and records an event" do
      post "/api/v1/legal_profiles/#{legal_profile.id}/submit_verification", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(json_body["verification_status"]).to eq("pending_review")

      event = legal_profile.reload.verification_events.last
      expect(event.event_type).to eq("submitted")
      expect(event.from_status).to eq("draft")
      expect(event.to_status).to eq("pending_review")
      expect(event.actor_user_id).to eq(owner.id)
    end

    it "returns 422 when profile is already pending_review" do
      legal_profile.update!(verification_status: :pending_review)

      post "/api/v1/legal_profiles/#{legal_profile.id}/submit_verification", headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "details", "verification_status")).to include(
        a_string_including("профиль можно отправить на проверку только из статуса черновика или отклонения")
      )
    end

    it "returns 403 for чужой seller" do
      stranger = create(:user, role: :seller)
      create(:seller_profile, user: stranger)

      post "/api/v1/legal_profiles/#{legal_profile.id}/submit_verification", headers: auth_headers(stranger)

      expect(response).to have_http_status(:forbidden)
      expect(json_body.dig("error", "key")).to eq("auth.pundit.forbidden")
    end
  end

  describe "POST /api/v1/legal_profiles/:id/approve" do
    let(:admin) { create(:user, role: :supermanager) }
    let(:legal_profile) { create(:legal_profile, :pending_review, seller_profile: seller_profile) }

    it "allows admin to approve profile and creates an event" do
      post "/api/v1/legal_profiles/#{legal_profile.id}/approve",
           headers: auth_headers(admin),
           params: { comment: "Документы проверены" }

      expect(response).to have_http_status(:ok)
      expect(json_body["verification_status"]).to eq("approved")
      expect(json_body["moderation_comment"]).to eq("Документы проверены")

      event = legal_profile.reload.verification_events.last
      expect(event.event_type).to eq("approved")
      expect(event.comment).to eq("Документы проверены")
      expect(event.actor_user_id).to eq(admin.id)
    end

    it "forbids seller to approve profile" do
      post "/api/v1/legal_profiles/#{legal_profile.id}/approve",
           headers: auth_headers(owner),
           params: { comment: "Не должно сработать" }

      expect(response).to have_http_status(:forbidden)
      expect(json_body.dig("error", "key")).to eq("auth.pundit.forbidden")
    end
  end

  describe "POST /api/v1/legal_profiles/:id/reject" do
    let(:admin) { create(:user, role: :superadmin) }
    let(:legal_profile) { create(:legal_profile, :pending_review, seller_profile: seller_profile) }

    it "allows admin to reject profile with comment and creates an event" do
      post "/api/v1/legal_profiles/#{legal_profile.id}/reject",
           headers: auth_headers(admin),
           params: { comment: "Нужно уточнить регистрационные данные" }

      expect(response).to have_http_status(:ok)
      expect(json_body["verification_status"]).to eq("rejected")
      expect(json_body["moderation_comment"]).to eq("Нужно уточнить регистрационные данные")

      event = legal_profile.reload.verification_events.last
      expect(event.event_type).to eq("rejected")
      expect(event.comment).to eq("Нужно уточнить регистрационные данные")
      expect(event.actor_user_id).to eq(admin.id)
    end
  end

  describe "GET /api/v1/legal_profiles/:id/verification_events" do
    let(:admin) { create(:user, role: :supermanager) }
    let(:legal_profile) { create(:legal_profile, :pending_review, seller_profile: seller_profile) }

    before do
      legal_profile.record_verification_event!(
        event_type: :submitted,
        actor_user: owner,
        from_status: :draft,
        to_status: :pending_review
      )
    end

    it "allows owner to see verification history" do
      get "/api/v1/legal_profiles/#{legal_profile.id}/verification_events", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(json_body.size).to eq(1)
      expect(json_body.first["event_type"]).to eq("submitted")
    end

    it "allows admin to see verification history" do
      get "/api/v1/legal_profiles/#{legal_profile.id}/verification_events", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_body.first["event_type"]).to eq("submitted")
    end

    it "forbids another seller from seeing verification history" do
      stranger = create(:user, role: :seller)
      create(:seller_profile, user: stranger)

      get "/api/v1/legal_profiles/#{legal_profile.id}/verification_events", headers: auth_headers(stranger)

      expect(response).to have_http_status(:forbidden)
      expect(json_body.dig("error", "key")).to eq("auth.pundit.forbidden")
    end
  end

  describe "PATCH /api/v1/legal_profiles/:id" do
    let(:legal_profile) { create(:legal_profile, seller_profile: seller_profile, verification_status: :approved, moderation_comment: "Старый комментарий") }

    it "resets approved profile to draft on critical field change" do
      patch "/api/v1/legal_profiles/#{legal_profile.id}",
            headers: auth_headers(owner),
            params: { legal_name: "TOO Updated Trade" }

      expect(response).to have_http_status(:ok)
      expect(json_body["verification_status"]).to eq("draft")
      expect(json_body["moderation_comment"]).to be_nil

      event = legal_profile.reload.verification_events.last
      expect(event.event_type).to eq("reset_to_draft")
      expect(event.from_status).to eq("approved")
      expect(event.to_status).to eq("draft")
      expect(event.actor_user_id).to eq(owner.id)
    end

    it "keeps approved status when only legal_address changes" do
      patch "/api/v1/legal_profiles/#{legal_profile.id}",
            headers: auth_headers(owner),
            params: { legal_address: "Астана, Туран 12" }

      expect(response).to have_http_status(:ok)
      expect(json_body["verification_status"]).to eq("approved")
      expect(json_body["legal_address"]).to eq("Астана, Туран 12")
      expect(legal_profile.reload.verification_events).to be_empty
    end
  end
end
