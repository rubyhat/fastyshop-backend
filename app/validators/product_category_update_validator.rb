# frozen_string_literal: true

# Валидатор при обновлении ProductCategory.
#
# Использует только общие проверки.
#
class ProductCategoryUpdateValidator < ActiveModel::Validator
  def validate(record)
    validate_level(record)
    validate_slug_uniqueness(record)
    validate_parent_exists(record)
  end
end
