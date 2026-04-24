# frozen_string_literal: true

class PublicLegalProfileTransparencySerializer < ActiveModel::Serializer
  attributes :id,
             :country_code,
             :legal_form_code,
             :legal_name,
             :registration_number_type,
             :registration_number_public,
             :verification_status
end
