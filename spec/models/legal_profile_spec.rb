require "rails_helper"

RSpec.describe LegalProfile, type: :model do
  let!(:country) do
    Country.find_or_create_by!(code: "KZ") do |record|
      record.name = "Казахстан"
      record.phone_prefix = "+7"
    end
  end

  describe "verification status" do
    it "defaults to draft" do
      profile = build(:legal_profile)

      expect(profile.verification_status).to eq("draft")
    end
  end

  describe "KZ validation rules" do
    it "allows self employed with iin" do
      profile = build(:legal_profile, :self_employed)

      expect(profile).to be_valid
    end

    it "rejects unsupported rollout country" do
      profile = build(:legal_profile, country_code: "RU")

      expect(profile).not_to be_valid
      expect(profile.errors[:country_code]).to include("страна временно не поддерживается для продавцов")
    end

    it "rejects invalid legal form and registration type pair" do
      profile = build(
        :legal_profile,
        legal_form_code: "limited_liability_partnership",
        registration_number_type: "iin"
      )

      expect(profile).not_to be_valid
      expect(profile.errors[:registration_number_type]).to include("не соответствует выбранной юридической форме")
    end

    it "rejects registration number with wrong KZ length" do
      profile = build(:legal_profile, registration_number: "123")

      expect(profile).not_to be_valid
      expect(profile.errors[:registration_number]).to include("должен содержать 12 цифр для Казахстана")
    end

    it "does not raise when registration number is blank" do
      profile = build(:legal_profile, registration_number: nil)

      expect(profile).not_to be_valid
      expect(profile.errors[:registration_number]).to include("can't be blank")
    end
  end

  describe "#registration_number_public" do
    it "returns bin publicly" do
      profile = build(:legal_profile)

      expect(profile.registration_number_public).to eq(profile.registration_number)
    end

    it "hides iin publicly" do
      profile = build(:legal_profile, :individual_entrepreneur)

      expect(profile.registration_number_public).to be_nil
    end
  end

  describe "#critical_fields_changed_for?" do
    it "does not treat formatted equal registration number as change" do
      profile = create(:legal_profile, registration_number: "123456789012")

      expect(
        profile.critical_fields_changed_for?({ registration_number: "123 456 789 012" })
      ).to be(false)
    end

    it "treats legal_name update as critical" do
      profile = create(:legal_profile)

      expect(profile.critical_fields_changed_for?({ legal_name: "New Name" })).to be(true)
    end
  end
end
