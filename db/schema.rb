# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_14_124409) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "countries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "phone_prefix", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
  end

  create_table "legal_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "seller_profile_id", null: false
    t.string "company_name", null: false
    t.string "tax_id", null: false
    t.string "country_code", null: false
    t.string "legal_address", null: false
    t.string "legal_form", null: false
    t.boolean "is_verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_profile_id"], name: "index_legal_profiles_on_seller_profile_id"
    t.index ["tax_id"], name: "index_legal_profiles_on_tax_id", unique: true
  end

  create_table "product_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "shop_id", null: false
    t.string "title", null: false
    t.string "slug", null: false
    t.uuid "parent_id"
    t.integer "level", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_product_categories_on_is_active"
    t.index ["level"], name: "index_product_categories_on_level"
    t.index ["parent_id"], name: "index_product_categories_on_parent_id"
    t.index ["position"], name: "index_product_categories_on_position"
    t.index ["shop_id"], name: "index_product_categories_on_shop_id"
    t.index ["title"], name: "index_product_categories_on_title"
  end

  create_table "product_properties", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "title", null: false
    t.integer "value_type", null: false
    t.integer "source_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_type"], name: "index_product_properties_on_source_type"
    t.index ["user_id", "title", "source_type"], name: "index_product_properties_on_user_id_and_title_and_source_type", unique: true
    t.index ["user_id"], name: "index_product_properties_on_user_id"
  end

  create_table "product_property_values", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "product_id", null: false
    t.uuid "product_property_id", null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "product_property_id"], name: "idx_on_product_id_product_property_id_769e0927c3", unique: true
    t.index ["product_id"], name: "index_product_property_values_on_product_id"
    t.index ["product_property_id"], name: "index_product_property_values_on_product_property_id"
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "shop_id", null: false
    t.uuid "product_category_id"
    t.string "title", null: false
    t.string "slug", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "position", null: false
    t.integer "product_type", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_products_on_is_active"
    t.index ["price"], name: "index_products_on_price"
    t.index ["product_category_id"], name: "index_products_on_product_category_id"
    t.index ["product_type"], name: "index_products_on_product_type"
    t.index ["shop_id", "slug"], name: "index_products_on_shop_id_and_slug", unique: true
    t.index ["shop_id"], name: "index_products_on_shop_id"
    t.index ["title"], name: "index_products_on_title"
  end

  create_table "seller_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "display_name", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_seller_profiles_on_slug", unique: true
    t.index ["user_id"], name: "index_seller_profiles_on_user_id", unique: true
  end

  create_table "shop_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.string "name", null: false
    t.text "description"
    t.string "icon"
    t.integer "position"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_shop_categories_on_is_active"
    t.index ["name"], name: "index_shop_categories_on_name", unique: true
    t.index ["position"], name: "index_shop_categories_on_position"
  end

  create_table "shops", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.string "contact_phone", null: false
    t.string "contact_email"
    t.string "physical_address"
    t.boolean "is_active", default: true, null: false
    t.integer "shop_type", null: false
    t.uuid "seller_profile_id", null: false
    t.uuid "legal_profile_id", null: false
    t.uuid "shop_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_shops_on_is_active"
    t.index ["legal_profile_id"], name: "index_shops_on_legal_profile_id"
    t.index ["seller_profile_id"], name: "index_shops_on_seller_profile_id"
    t.index ["shop_category_id"], name: "index_shops_on_shop_category_id"
    t.index ["shop_type"], name: "index_shops_on_shop_type"
    t.index ["slug"], name: "index_shops_on_slug", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "phone", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 3, null: false
    t.string "country_code", default: "KZ", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
  end

  add_foreign_key "product_categories", "shops"
  add_foreign_key "product_properties", "users"
  add_foreign_key "product_property_values", "product_properties"
  add_foreign_key "product_property_values", "products"
  add_foreign_key "products", "product_categories"
  add_foreign_key "products", "shops"
end
