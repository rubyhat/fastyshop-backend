class ImplementBe05CartOrderCore < ActiveRecord::Migration[8.1]
  def up
    add_column :shops, :orders_counter, :integer, null: false, default: 0

    add_column :carts, :status, :integer, null: false, default: 0
    add_column :carts, :converted_at, :datetime

    remove_index :carts, name: "index_carts_on_user_id_and_shop_id", if_exists: true
    add_index :carts, %i[user_id shop_id status]
    add_index :carts,
              %i[user_id shop_id],
              unique: true,
              where: "status = 0",
              name: "idx_unique_active_carts_on_user_shop"

    add_column :orders, :order_number, :integer
    add_column :orders, :customer_snapshot, :jsonb, null: false, default: {}
    add_column :orders, :customer_comment, :text
    add_column :orders, :inventory_restored_at, :datetime
    add_column :orders, :checkout_idempotency_key, :string

    create_table :order_events, id: :uuid do |t|
      t.references :order, null: false, type: :uuid, foreign_key: true
      t.references :actor_user, null: true, type: :uuid, foreign_key: { to_table: :users }
      t.integer :event_type, null: false
      t.string :from_status
      t.string :to_status
      t.text :comment
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :order_events, %i[order_id created_at]
    add_index :order_events, :event_type

    migrate_order_statuses
    migrate_order_customer_snapshots
    migrate_order_numbers
    migrate_shop_order_counters
    migrate_order_events

    change_column_null :orders, :order_number, false

    add_index :orders, %i[shop_id order_number], unique: true
    add_index :orders,
              %i[user_id shop_id checkout_idempotency_key],
              unique: true,
              where: "checkout_idempotency_key IS NOT NULL",
              name: "idx_orders_on_user_shop_checkout_key"

    remove_column :orders, :canceled_by_user, :boolean
    remove_column :orders, :contact_name, :string
    remove_column :orders, :contact_phone, :string
    remove_column :orders, :delivery_address_text, :string
    remove_column :orders, :delivery_comment, :string
    remove_column :orders, :delivery_method, :integer
    remove_column :orders, :payment_method, :integer
    remove_column :orders, :status_comment, :string
  end

  def down
    add_column :orders, :canceled_by_user, :boolean, default: false
    add_column :orders, :contact_name, :string, null: false, default: "Покупатель"
    add_column :orders, :contact_phone, :string, null: false, default: "77000000000"
    add_column :orders, :delivery_address_text, :string, null: false, default: "Не указан"
    add_column :orders, :delivery_comment, :string
    add_column :orders, :delivery_method, :integer, null: false, default: 0
    add_column :orders, :payment_method, :integer, null: false, default: 0
    add_column :orders, :status_comment, :string

    execute <<~SQL.squish
      UPDATE orders
      SET status = CASE
        WHEN status = 7 THEN 6
        WHEN status = 6 THEN 5
        ELSE status
      END,
      canceled_by_user = CASE
        WHEN status = 6 THEN TRUE
        ELSE FALSE
      END,
      contact_name = COALESCE(customer_snapshot->>'full_name', 'Покупатель'),
      contact_phone = COALESCE(
        NULLIF(customer_snapshot->>'phone', ''),
        '77000000000'
      ),
      delivery_address_text = 'Не указан',
      delivery_comment = customer_comment,
      delivery_method = 0,
      payment_method = 0
    SQL

    remove_index :orders, name: "idx_orders_on_user_shop_checkout_key", if_exists: true
    remove_index :orders, %i[shop_id order_number], if_exists: true

    remove_column :orders, :checkout_idempotency_key, :string
    remove_column :orders, :inventory_restored_at, :datetime
    remove_column :orders, :customer_comment, :text
    remove_column :orders, :customer_snapshot, :jsonb
    remove_column :orders, :order_number, :integer

    drop_table :order_events

    remove_index :carts, name: "idx_unique_active_carts_on_user_shop", if_exists: true
    remove_index :carts, %i[user_id shop_id status], if_exists: true
    add_index :carts, %i[user_id shop_id], unique: true

    remove_column :carts, :converted_at, :datetime
    remove_column :carts, :status, :integer

    remove_column :shops, :orders_counter, :integer
  end

  private

  def migrate_order_statuses
    execute <<~SQL.squish
      UPDATE orders
      SET status = CASE
        WHEN status = 6 THEN 7
        WHEN status = 5 THEN 6
        ELSE status
      END
    SQL
  end

  def migrate_order_customer_snapshots
    execute <<~SQL.squish
      UPDATE orders AS o
      SET customer_snapshot = jsonb_build_object(
        'full_name',
        COALESCE(
          NULLIF(o.contact_name, ''),
          NULLIF(CONCAT_WS(' ', u.first_name, u.last_name, u.middle_name), ''),
          CONCAT('Покупатель ', COALESCE(u.phone, ''))
        ),
        'phone',
        CASE
          WHEN NULLIF(REGEXP_REPLACE(COALESCE(o.contact_phone, ''), '\D', '', 'g'), '') IS NOT NULL
            THEN CONCAT('+', REGEXP_REPLACE(o.contact_phone, '\D', '', 'g'))
          WHEN NULLIF(u.phone, '') IS NOT NULL
            THEN CONCAT('+', u.phone)
          ELSE NULL
        END,
        'email',
        u.email
      ),
      customer_comment = o.delivery_comment
      FROM users AS u
      WHERE o.user_id = u.id
    SQL
  end

  def migrate_order_numbers
    execute <<~SQL.squish
      WITH numbered AS (
        SELECT
          id,
          ROW_NUMBER() OVER (PARTITION BY shop_id ORDER BY created_at ASC, id ASC) AS seq
        FROM orders
      )
      UPDATE orders AS o
      SET order_number = numbered.seq
      FROM numbered
      WHERE o.id = numbered.id
    SQL
  end

  def migrate_shop_order_counters
    execute <<~SQL.squish
      UPDATE shops AS s
      SET orders_counter = COALESCE(counters.max_order_number, 0)
      FROM (
        SELECT shop_id, MAX(order_number) AS max_order_number
        FROM orders
        GROUP BY shop_id
      ) AS counters
      WHERE s.id = counters.shop_id
    SQL
  end

  def migrate_order_events
    execute <<~SQL.squish
      INSERT INTO order_events (
        id,
        order_id,
        actor_user_id,
        event_type,
        from_status,
        to_status,
        comment,
        metadata,
        created_at,
        updated_at
      )
      SELECT
        gen_random_uuid(),
        o.id,
        NULL,
        CASE
          WHEN o.status = 0 THEN 0
          WHEN o.status = 1 THEN 1
          WHEN o.status = 2 THEN 5
          WHEN o.status = 3 THEN 6
          WHEN o.status = 4 THEN 7
          WHEN o.status = 6 THEN 3
          WHEN o.status = 7 THEN 4
          ELSE 0
        END,
        NULL,
        CASE
          WHEN o.status = 0 THEN 'created'
          WHEN o.status = 1 THEN 'accepted'
          WHEN o.status = 2 THEN 'in_progress'
          WHEN o.status = 3 THEN 'ready'
          WHEN o.status = 4 THEN 'completed'
          WHEN o.status = 6 THEN 'canceled_by_user'
          WHEN o.status = 7 THEN 'canceled_by_seller'
          ELSE 'created'
        END,
        o.status_comment,
        '{}'::jsonb,
        o.created_at,
        o.updated_at
      FROM orders AS o
    SQL
  end
end
