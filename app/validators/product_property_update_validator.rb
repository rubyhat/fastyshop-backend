class ProductPropertyUpdateValidator  < ActiveModel::Validator
  def validate(record)
    prevent_non_admin_editing_global_property(record)
  end

  def prevent_non_admin_editing_global_property(record)
    return unless record.source_type == "global"

    unless record.user.superadmin? || record.user.supermanager?
      record.errors.add(:base, "Вы не можете редактировать системные свойства!")
    end
  end
end
