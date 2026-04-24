class ImplementBe04CatalogLifecycle < ActiveRecord::Migration[8.1]
  def up
    add_lifecycle_columns(:product_categories)
    add_lifecycle_columns(:products)

    add_column :products, :sku, :string
    add_column :products, :image_url, :string
    add_column :order_items, :product_snapshot, :jsonb, null: false, default: {}

    create_catalog_lifecycle_events

    migrate_product_category_statuses
    migrate_product_statuses
    migrate_product_types

    remove_index :product_categories, :is_active, if_exists: true
    remove_index :products, :is_active, if_exists: true
    remove_column :product_categories, :is_active
    remove_column :products, :is_active

    add_catalog_indexes
  end

  def down
    remove_catalog_indexes

    add_column :product_categories, :is_active, :boolean, null: false, default: true
    add_column :products, :is_active, :boolean, null: false, default: true

    execute <<~SQL.squish
      UPDATE product_categories
      SET is_active = CASE
        WHEN status = 2 THEN FALSE
        ELSE TRUE
      END
    SQL

    execute <<~SQL.squish
      UPDATE products
      SET is_active = CASE
        WHEN status = 2 THEN FALSE
        ELSE TRUE
      END
    SQL

    execute <<~SQL.squish
      UPDATE products
      SET product_type = CASE
        WHEN product_type = 2 THEN 1
        ELSE 0
      END
    SQL

    add_index :product_categories, :is_active
    add_index :products, :is_active

    drop_table :catalog_lifecycle_events

    remove_column :order_items, :product_snapshot
    remove_column :products, :image_url
    remove_column :products, :sku

    remove_lifecycle_columns(:products)
    remove_lifecycle_columns(:product_categories)
  end

  private

  def add_lifecycle_columns(table_name)
    add_column table_name, :status, :integer, null: false, default: 0
    add_reference table_name, :published_by, null: true, type: :uuid, foreign_key: { to_table: :users }
    add_reference table_name, :archived_by, null: true, type: :uuid, foreign_key: { to_table: :users }
    add_column table_name, :published_at, :datetime
    add_column table_name, :archived_at, :datetime
  end

  def remove_lifecycle_columns(table_name)
    remove_column table_name, :archived_at
    remove_column table_name, :published_at
    remove_reference table_name, :archived_by, type: :uuid, foreign_key: { to_table: :users }
    remove_reference table_name, :published_by, type: :uuid, foreign_key: { to_table: :users }
    remove_column table_name, :status
  end

  def create_catalog_lifecycle_events
    create_table :catalog_lifecycle_events, id: :uuid do |t|
      t.string :record_type, null: false
      t.uuid :record_id, null: false
      t.references :actor_user, null: true, type: :uuid, foreign_key: { to_table: :users }
      t.integer :event_type, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :catalog_lifecycle_events, %i[record_type record_id created_at],
              name: "idx_catalog_lifecycle_events_on_record_created"
    add_index :catalog_lifecycle_events, :event_type
  end

  def migrate_product_category_statuses
    execute <<~SQL.squish
      UPDATE product_categories
      SET status = CASE
        WHEN is_active = TRUE THEN 1
        ELSE 2
      END,
      published_at = CASE
        WHEN is_active = TRUE THEN updated_at
        ELSE NULL
      END,
      archived_at = CASE
        WHEN is_active = FALSE THEN updated_at
        ELSE NULL
      END
    SQL
  end

  def migrate_product_statuses
    execute <<~SQL.squish
      UPDATE products
      SET status = CASE
        WHEN is_active = TRUE THEN 1
        ELSE 2
      END,
      published_at = CASE
        WHEN is_active = TRUE THEN updated_at
        ELSE NULL
      END,
      archived_at = CASE
        WHEN is_active = FALSE THEN updated_at
        ELSE NULL
      END
    SQL
  end

  def migrate_product_types
    execute <<~SQL.squish
      UPDATE products
      SET product_type = CASE
        WHEN product_type = 1 THEN 2
        ELSE 0
      END
    SQL
  end

  def add_catalog_indexes
    add_index :product_categories, %i[shop_id status]
    add_index :product_categories, %i[parent_id status]
    add_index :product_categories, %i[shop_id parent_id position], name: "idx_product_categories_on_shop_parent_position"

    add_index :products, %i[shop_id status]
    add_index :products, %i[shop_id product_category_id status], name: "idx_products_on_shop_category_status"
    add_index :products, :sku
  end

  def remove_catalog_indexes
    remove_index :products, :sku, if_exists: true
    remove_index :products, name: "idx_products_on_shop_category_status", if_exists: true
    remove_index :products, %i[shop_id status], if_exists: true

    remove_index :product_categories, name: "idx_product_categories_on_shop_parent_position", if_exists: true
    remove_index :product_categories, %i[parent_id status], if_exists: true
    remove_index :product_categories, %i[shop_id status], if_exists: true
  end
end
