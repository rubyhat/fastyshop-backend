class AddAccountStatusToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :account_status, :integer, null: false, default: 0

    execute <<~SQL.squish
      UPDATE users
      SET account_status = CASE
        WHEN is_active = TRUE THEN 1
        ELSE 4
      END
    SQL

    execute <<~SQL.squish
      UPDATE users
      SET phone = regexp_replace(phone, '\\D', '', 'g'),
          email = lower(btrim(email))
    SQL

    add_index :users, :account_status

    remove_index :users, :email, if_exists: true
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"

    remove_column :users, :is_active
  end

  def down
    add_column :users, :is_active, :boolean, null: false, default: true

    execute <<~SQL.squish
      UPDATE users
      SET is_active = CASE
        WHEN account_status = 4 THEN FALSE
        ELSE TRUE
      END
    SQL

    remove_index :users, name: "index_users_on_lower_email", if_exists: true
    add_index :users, :email, unique: true

    remove_index :users, :account_status, if_exists: true
    remove_column :users, :account_status
  end
end
