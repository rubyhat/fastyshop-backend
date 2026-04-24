# frozen_string_literal: true

class LegalProfileSerializer < ActiveModel::Serializer
  attributes :id,
             :legal_name,
             :country_code,
             :legal_form_code,
             :registration_number_type,
             :registration_number,
             :legal_address,
             :verification_status,
             :moderation_comment,
             :seller_profile_id,
             :created_at,
             :updated_at
end
