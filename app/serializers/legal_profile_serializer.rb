class LegalProfileSerializer < ActiveModel::Serializer
  attributes :id,
             :company_name,
             :tax_id,
             :country_code,
             :legal_address,
             :legal_form,
             :is_verified,
             :seller_profile_id,
             :created_at,
             :updated_at
end
