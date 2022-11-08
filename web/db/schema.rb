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

ActiveRecord::Schema[7.0].define(version: 2022_11_07_210313) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "orders", force: :cascade do |t|
    t.bigint "shop_id"
    t.string "shopify_id"
    t.datetime "due_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "financial_status", null: false
    t.string "email", null: false
    t.datetime "shopify_created_at"
    t.integer "returns_count"
    t.string "mandate_id"
    t.string "fulfillment_status", default: "UNFULFILLED"
    t.datetime "closed_at"
    t.datetime "shopify_updated_at"
    t.index ["shop_id"], name: "index_orders_on_shop_id"
    t.index ["shopify_id"], name: "unique_shopify_ids", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.string "idempotency_key", null: false
    t.string "payment_reference_id"
    t.string "error"
    t.string "status", default: "PENDING"
    t.bigint "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_payments_on_idempotency_key", unique: true
    t.index ["order_id"], name: "index_payments_on_order_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "name", null: false
    t.integer "trial_days", default: 0
    t.decimal "price", precision: 8, scale: 2, null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.string "shopify_id", null: false
    t.bigint "shop_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_products_on_shop_id"
    t.index ["shopify_id"], name: "index_products_on_shopify_id", unique: true
  end

  create_table "returns", force: :cascade do |t|
    t.bigint "shop_id"
    t.bigint "order_id"
    t.string "shopify_id"
    t.string "title"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_returns_on_order_id"
    t.index ["shop_id"], name: "index_returns_on_shop_id"
    t.index ["shopify_id"], name: "index_returns_on_shopify_id", unique: true
  end

  create_table "selling_plan_groups", force: :cascade do |t|
    t.string "shopify_id", null: false
    t.string "name", default: "Free trial", null: false
    t.text "description", default: "Your free trial program"
    t.bigint "shop_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_selling_plan_groups_on_shop_id"
    t.index ["shopify_id"], name: "index_selling_plan_groups_on_shopify_id", unique: true
  end

  create_table "selling_plans", force: :cascade do |t|
    t.string "shopify_id"
    t.string "name", default: "Free trial", null: false
    t.text "description", default: "Try this product free for 14 days"
    t.integer "prepay", default: 0
    t.integer "trial_days", default: 14
    t.bigint "selling_plan_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["selling_plan_group_id"], name: "index_selling_plans_on_selling_plan_group_id"
    t.index ["shopify_id"], name: "index_selling_plans_on_shopify_id", unique: true
  end

  create_table "shops", force: :cascade do |t|
    t.string "shopify_domain", null: false
    t.string "shopify_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "access_scopes"
    t.string "klaviyo_public_key"
    t.string "klaviyo_private_key"
    t.bigint "plan_id"
    t.datetime "orders_updated_at"
    t.string "order_number_format_prefix", default: "#"
    t.string "order_number_format_suffix"
    t.string "email"
    t.boolean "onboarded", default: false
    t.integer "return_period", default: 14, null: false
    t.text "return_explainer"
    t.boolean "allow_automatic_payments", default: true
    t.integer "max_trial_items", default: 3
    t.index ["plan_id"], name: "index_shops_on_plan_id"
    t.index ["shopify_domain"], name: "index_shops_on_shopify_domain", unique: true
  end

  add_foreign_key "orders", "shops", on_delete: :cascade
  add_foreign_key "payments", "orders"
  add_foreign_key "products", "shops", on_delete: :cascade
  add_foreign_key "returns", "orders", on_delete: :cascade
  add_foreign_key "selling_plan_groups", "shops", on_delete: :cascade
  add_foreign_key "selling_plans", "selling_plan_groups", on_delete: :cascade
end
