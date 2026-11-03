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

ActiveRecord::Schema[7.2].define(version: 2026_11_03_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "action", null: false
    t.string "resource"
    t.integer "resource_id"
    t.text "details"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "branches", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "address"
    t.string "phone_primary"
    t.string "phone_secondary"
    t.string "established_year"
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_url"
    t.string "tagline"
    t.text "opening_hours"
    t.string "map_url"
    t.string "venue_type", default: "pub", null: false
    t.integer "position", default: 0, null: false
    t.string "eyebrow"
    t.string "story_title"
    t.text "story"
    t.jsonb "stats", default: [], null: false
    t.jsonb "features", default: [], null: false
    t.jsonb "signatures", default: [], null: false
    t.string "signatures_title"
    t.index ["slug"], name: "index_branches_on_slug", unique: true
  end

  create_table "event_bookings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "event_id", null: false
    t.bigint "branch_id", null: false
    t.integer "guests", default: 1
    t.string "status", default: "pending"
    t.text "notes"
    t.string "confirmation_code", null: false
    t.datetime "confirmed_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_event_bookings_on_branch_id"
    t.index ["confirmation_code"], name: "index_event_bookings_on_confirmation_code", unique: true
    t.index ["event_id"], name: "index_event_bookings_on_event_id"
    t.index ["user_id", "event_id"], name: "index_event_bookings_on_user_id_and_event_id"
    t.index ["user_id"], name: "index_event_bookings_on_user_id"
  end

  create_table "event_bookmarks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_bookmarks_on_event_id"
    t.index ["user_id", "event_id"], name: "index_event_bookmarks_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_event_bookmarks_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "title", null: false
    t.string "event_type", default: "match", null: false
    t.string "league_or_category"
    t.string "badge"
    t.text "description"
    t.bigint "branch_id"
    t.date "date_start", null: false
    t.date "date_end"
    t.string "time_local"
    t.string "venue_or_city"
    t.string "image_url"
    t.string "status", default: "scheduled"
    t.integer "priority", default: 0
    t.string "source", default: "manual"
    t.boolean "featured", default: false
    t.boolean "is_global", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "recurrence", default: "none", null: false
    t.string "days_of_week"
    t.string "time_end"
    t.string "area"
    t.index ["branch_id"], name: "index_events_on_branch_id"
    t.index ["date_start"], name: "index_events_on_date_start"
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["recurrence"], name: "index_events_on_recurrence"
    t.index ["status"], name: "index_events_on_status"
  end

  create_table "media_items", force: :cascade do |t|
    t.string "title"
    t.string "media_type", default: "image"
    t.string "file_url", null: false
    t.string "thumbnail_url"
    t.bigint "branch_id"
    t.boolean "featured", default: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_media_items_on_branch_id"
  end

  create_table "member_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date_of_birth"
    t.string "favorite_branch"
    t.string "preferred_sports"
    t.text "bio"
    t.boolean "notifications_enabled", default: true
    t.boolean "marketing_emails", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_member_profiles_on_user_id"
  end

  create_table "menu_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "menu_type", default: "food", null: false
    t.integer "position", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "menu_items", force: :cascade do |t|
    t.bigint "menu_category_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2
    t.string "image_url"
    t.boolean "available", default: true
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_category_id"], name: "index_menu_items_on_menu_category_id"
  end

  create_table "menu_pdfs", force: :cascade do |t|
    t.string "title", null: false
    t.string "pdf_type", default: "food"
    t.string "file_url"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "stored_file_id"
    t.integer "position", default: 0, null: false
    t.index ["stored_file_id"], name: "index_menu_pdfs_on_stored_file_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "body"
    t.string "notif_type", default: "info"
    t.boolean "read", default: false
    t.string "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.boolean "revoked", default: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_refresh_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "site_settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.string "group", default: "general"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_site_settings_on_key", unique: true
  end

  create_table "stored_files", force: :cascade do |t|
    t.string "filename", null: false
    t.string "content_type", null: false
    t.integer "byte_size", null: false
    t.string "checksum", null: false
    t.binary "data", null: false
    t.string "purpose"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checksum"], name: "index_stored_files_on_checksum"
  end

  create_table "table_reservations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "branch_id", null: false
    t.date "date", null: false
    t.string "time", null: false
    t.integer "guests", default: 2, null: false
    t.string "status", default: "pending"
    t.text "notes"
    t.string "occasion"
    t.string "confirmation_code", null: false
    t.datetime "confirmed_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_table_reservations_on_branch_id"
    t.index ["confirmation_code"], name: "index_table_reservations_on_confirmation_code", unique: true
    t.index ["user_id"], name: "index_table_reservations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "member", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "avatar_url"
    t.bigint "branch_id"
    t.boolean "active", default: true
    t.datetime "last_login_at"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_users_on_branch_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "audit_logs", "users"
  add_foreign_key "event_bookings", "branches"
  add_foreign_key "event_bookings", "events"
  add_foreign_key "event_bookings", "users"
  add_foreign_key "event_bookmarks", "events"
  add_foreign_key "event_bookmarks", "users"
  add_foreign_key "events", "branches"
  add_foreign_key "media_items", "branches"
  add_foreign_key "member_profiles", "users"
  add_foreign_key "menu_items", "menu_categories"
  add_foreign_key "menu_pdfs", "stored_files", on_delete: :nullify
  add_foreign_key "notifications", "users"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "table_reservations", "branches"
  add_foreign_key "table_reservations", "users"
  add_foreign_key "users", "branches"
end
