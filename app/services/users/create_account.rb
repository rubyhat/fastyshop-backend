# frozen_string_literal: true

module Users
  # CreateAccount хранит правила создания аккаунтов в одном месте для публичной регистрации и админского сценария.
  class CreateAccount
    ADMIN_CREATABLE_ROLES = %w[user seller supermanager].freeze

    class << self
      # @param attributes [ActionController::Parameters, Hash]
      # @return [User]
      def for_signup(attributes)
        new(
          attributes: attributes,
          role: :user,
          account_status: :pending_review
        ).call
      end

      # @param attributes [ActionController::Parameters, Hash]
      # @return [User]
      def for_admin(attributes)
        normalized_attributes = normalize_attributes(attributes)
        role = normalized_attributes.delete(:role).presence || :user
        account_status = normalized_attributes.delete(:account_status).presence || :approved

        new(
          attributes: normalized_attributes,
          role: role,
          account_status: account_status,
          admin_flow: true
        ).call
      end

      private

      def normalize_attributes(attributes)
        attributes.to_h.deep_symbolize_keys
      end
    end

    # @param attributes [ActionController::Parameters, Hash]
    # @param role [String, Symbol]
    # @param account_status [String, Symbol]
    # @param admin_flow [Boolean]
    def initialize(attributes:, role:, account_status:, admin_flow: false)
      @attributes = attributes.to_h.deep_symbolize_keys.except(:role, :account_status)
      @role = role.to_s
      @account_status = account_status.to_s
      @admin_flow = admin_flow
    end

    # @return [User]
    def call
      user = User.new(attributes)

      return invalid_user(user, :role, "недопустимая роль") unless valid_role?
      return invalid_user(user, :account_status, "недопустимый статус аккаунта") unless valid_account_status?

      user.role = role
      user.account_status = account_status
      user.save
      user
    end

    private

    attr_reader :attributes, :role, :account_status, :admin_flow

    def valid_role?
      return ADMIN_CREATABLE_ROLES.include?(role) if admin_flow

      role == "user"
    end

    def valid_account_status?
      User.account_statuses.key?(account_status)
    end

    def invalid_user(user, attribute, message)
      user.errors.add(attribute, message)
      user
    end
  end
end
