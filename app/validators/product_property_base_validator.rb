class ProductPropertyBaseValidator < ActiveModel::Validator
  def validate(record)
    validate_global_restriction(record)
  end

  # Глобальные свойства может создавать только админ
  def validate_global_restriction(record)
    return unless record.source_type == "global"

    if record.user_id.present?
      record.errors.add(:user_id, "должен быть пустым для глобального свойства")
    end
  end
end
