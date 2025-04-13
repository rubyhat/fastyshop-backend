class ShopPolicy < ApplicationPolicy
    def index?
      true
    end

    def show?
      true
    end

    def create?
      (user.present? && user.seller?) || user.superadmin? || user.supermanager?
    end

    def update?
      user.superadmin? || user.supermanager? || owns_shop?
    end

    def destroy?
      user.superadmin? || user.supermanager? || owns_shop?
    end

    class Scope < Scope
      def resolve_catalog
        scope.where(is_active: true)
      end

      def resolve_owner_view
        if user&.superadmin? || user&.supermanager?
          scope.all
        elsif user&.seller_profile
          scope.where(seller_profile_id: user.seller_profile.id)
        else
          # Покупатель — видит только активные магазины конкретного продавца
          scope.where(seller_profile_id: user&.seller_profile&.id, is_active: true)
        end
      end
    end

    private

    def owns_shop?
      record.respond_to?(:seller_profile) &&
        record.seller_profile.user_id == user.id
    end
end
