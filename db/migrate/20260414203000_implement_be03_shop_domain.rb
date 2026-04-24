class ImplementBe03ShopDomain < ActiveRecord::Migration[8.1]
  def up
    add_column :shops, :description, :text
    add_column :shops, :logo_url, :string
    add_column :shops, :status, :integer, null: false, default: 0
    add_column :shops, :status_comment, :text

    execute <<~SQL.squish
      UPDATE shops
      SET status = CASE
        WHEN is_active = TRUE THEN 0
        ELSE 1
      END
    SQL

    add_index :shops, :status
    remove_index :shops, :is_active, if_exists: true
    remove_column :shops, :is_active

    create_table :shop_slug_histories, id: :uuid do |t|
      t.references :shop, null: false, type: :uuid, foreign_key: true
      t.string :slug, null: false

      t.timestamps
    end

    add_index :shop_slug_histories, :slug, unique: true
    add_index :shop_slug_histories, %i[shop_id created_at]

    create_table :shop_change_events, id: :uuid do |t|
      t.references :shop, null: false, type: :uuid, foreign_key: true
      t.references :actor_user, null: true, type: :uuid, foreign_key: { to_table: :users }
      t.integer :event_type, null: false
      t.jsonb :changeset, null: false, default: {}

      t.timestamps
    end

    add_index :shop_change_events, %i[shop_id created_at]
    add_index :shop_change_events, :event_type

    create_table :slug_blocklist_entries, id: :uuid do |t|
      t.string :term, null: false
      t.integer :match_type, null: false, default: 0
      t.boolean :is_active, null: false, default: true
      t.text :comment

      t.timestamps
    end

    add_index :slug_blocklist_entries, :term, unique: true
    add_index :slug_blocklist_entries, :is_active

    add_column :orders, :shop_snapshot, :jsonb, null: false, default: {}
    add_column :orders, :legal_profile_snapshot, :jsonb, null: false, default: {}
  end

  def down
    remove_column :orders, :legal_profile_snapshot
    remove_column :orders, :shop_snapshot

    drop_table :slug_blocklist_entries
    drop_table :shop_change_events
    drop_table :shop_slug_histories

    add_column :shops, :is_active, :boolean, null: false, default: true

    execute <<~SQL.squish
      UPDATE shops
      SET is_active = CASE
        WHEN status = 0 THEN TRUE
        ELSE FALSE
      END
    SQL

    add_index :shops, :is_active
    remove_index :shops, :status, if_exists: true
    remove_column :shops, :status_comment
    remove_column :shops, :status
    remove_column :shops, :logo_url
    remove_column :shops, :description
  end
end
