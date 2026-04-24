# frozen_string_literal: true

module Orders
  # CustomerSnapshot builds immutable buyer contact data for an order.
  class CustomerSnapshot
    # @param user [User]
    # @param contact_name [String, nil]
    # @param contact_phone [String, nil]
    def initialize(user:, contact_name:, contact_phone:)
      @user = user
      @contact_name = contact_name
      @contact_phone = contact_phone
    end

    # @return [Hash]
    def call
      {
        full_name: resolved_full_name,
        phone: resolved_phone,
        email: user.email
      }
    end

    private

    attr_reader :user, :contact_name, :contact_phone

    def resolved_full_name
      contact_name.to_s.strip.presence || user.full_name
    end

    def resolved_phone
      digits = User.normalize_phone(contact_phone.presence || user.phone)
      digits.present? ? "+#{digits}" : nil
    end
  end
end
