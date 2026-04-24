class LegalProfile < ApplicationRecord
  ROLLED_OUT_COUNTRIES = %w[KZ].freeze
  LEGAL_FORMS_BY_COUNTRY = {
    "KZ" => %w[self_employed individual_entrepreneur limited_liability_partnership].freeze
  }.freeze
  REGISTRATION_TYPE_BY_LEGAL_FORM = {
    "KZ" => {
      "self_employed" => "iin",
      "individual_entrepreneur" => "iin",
      "limited_liability_partnership" => "bin"
    }.freeze
  }.freeze
  LEGAL_FORM_LABELS = {
    "self_employed" => "Самозанятый",
    "individual_entrepreneur" => "ИП",
    "limited_liability_partnership" => "ТОО"
  }.freeze
  CRITICAL_VERIFICATION_FIELDS = %w[
    country_code
    legal_form_code
    legal_name
    registration_number_type
    registration_number
  ].freeze

  belongs_to :seller_profile
  has_many :shops, dependent: :restrict_with_error
  has_many :verification_events,
           class_name: "LegalProfileVerificationEvent",
           dependent: :destroy,
           inverse_of: :legal_profile

  before_validation :normalize_country_code
  before_validation :normalize_registration_number

  enum :verification_status, {
    draft: 0,
    pending_review: 1,
    approved: 2,
    rejected: 3
  }, default: :draft

  validates :legal_name, presence: true, length: { maximum: 255 }
  validates :country_code, presence: true, length: { is: 2 }
  validates :legal_form_code, presence: true, length: { maximum: 100 }
  validates :registration_number_type, presence: true, length: { maximum: 32 }
  validates :registration_number,
            presence: true,
            length: { maximum: 32 },
            uniqueness: { scope: %i[country_code registration_number_type], case_sensitive: false }
  validates :legal_address, length: { maximum: 500 }
  validates :moderation_comment, length: { maximum: 2000 }, allow_blank: true

  validates_with LegalProfileValidator

  # @return [String, nil]
  def registration_number_public
    registration_number_type == "bin" ? registration_number : nil
  end

  # @return [Boolean]
  def verified_badge?
    approved?
  end

  # @return [String]
  def legal_form_label
    LEGAL_FORM_LABELS.fetch(legal_form_code, legal_form_code.to_s)
  end

  # @return [String, nil]
  def legal_address_public
    legal_form_code == "limited_liability_partnership" ? legal_address : nil
  end

  # @param event_type [Symbol, String]
  # @param actor_user [User, nil]
  # @param from_status [String, Symbol, nil]
  # @param to_status [String, Symbol, nil]
  # @param comment [String, nil]
  # @param metadata [Hash]
  # @return [LegalProfileVerificationEvent]
  def record_verification_event!(event_type:, actor_user:, from_status:, to_status:, comment: nil, metadata: {})
    verification_events.create!(
      event_type: event_type,
      actor_user: actor_user,
      from_status: from_status&.to_s,
      to_status: to_status&.to_s,
      comment: comment,
      metadata: metadata
    )
  end

  # @param attributes [Hash]
  # @return [Boolean]
  def critical_fields_changed_for?(attributes)
    attributes.stringify_keys.any? do |attribute, value|
      next false unless CRITICAL_VERIFICATION_FIELDS.include?(attribute)

      current_value =
        case attribute
        when "country_code"
          public_send(attribute).to_s.upcase
        when "registration_number"
          public_send(attribute).to_s.gsub(/\D/, "")
        else
          public_send(attribute).to_s
        end

      incoming_value =
        case attribute
        when "country_code"
          value.to_s.upcase
        when "registration_number"
          value.to_s.gsub(/\D/, "")
        else
          value.to_s
        end

      current_value != incoming_value
    end
  end

  # @return [String, nil]
  def expected_registration_number_type
    REGISTRATION_TYPE_BY_LEGAL_FORM.dig(country_code, legal_form_code)
  end

  private

  def normalize_country_code
    self.country_code = country_code.to_s.strip.upcase if country_code.present?
  end

  def normalize_registration_number
    self.registration_number = registration_number.to_s.gsub(/\D/, "") if registration_number.present?
  end
end
