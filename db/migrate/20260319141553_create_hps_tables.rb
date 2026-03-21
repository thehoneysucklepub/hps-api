class CreateHpsTables < ActiveRecord::Migration[7.2]
  def change

    # ─── BRANCHES ───────────────────────────────────────────────
    create_table :branches do |t|
      t.string   :name,           null: false
      t.string   :slug,           null: false
      t.string   :address
      t.string   :phone_primary
      t.string   :phone_secondary
      t.string   :established_year
      t.text     :description
      t.boolean  :active,         default: true
      t.timestamps
    end
    add_index :branches, :slug, unique: true

    # ─── USERS ──────────────────────────────────────────────────
    create_table :users do |t|
      t.string   :username,       null: false
      t.string   :email,          null: false
      t.string   :password_digest, null: false
      t.string   :role,           null: false, default: "member"
      t.string   :first_name
      t.string   :last_name
      t.string   :phone
      t.string   :avatar_url
      t.references :branch,       foreign_key: true
      t.boolean  :active,         default: true
      t.datetime :last_login_at
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.timestamps
    end
    add_index :users, :username, unique: true
    add_index :users, :email,    unique: true

    # ─── REFRESH TOKENS ─────────────────────────────────────────
    create_table :refresh_tokens do |t|
      t.references :user,         null: false, foreign_key: true
      t.string     :token,        null: false
      t.datetime   :expires_at,   null: false
      t.boolean    :revoked,      default: false
      t.string     :ip_address
      t.string     :user_agent
      t.timestamps
    end
    add_index :refresh_tokens, :token, unique: true

    # ─── EVENTS ─────────────────────────────────────────────────
    create_table :events do |t|
      t.string     :title,              null: false
      t.string     :event_type,         null: false, default: "match"
      t.string     :league_or_category
      t.string     :badge
      t.text       :description
      t.references :branch,             foreign_key: true
      t.date       :date_start,         null: false
      t.date       :date_end
      t.string     :time_local
      t.string     :venue_or_city
      t.string     :image_url
      t.string     :status,             default: "scheduled"
      t.integer    :priority,           default: 0
      t.string     :source,             default: "manual"
      t.boolean    :featured,           default: false
      t.boolean    :is_global,          default: false
      t.timestamps
    end
    add_index :events, :date_start
    add_index :events, :status
    add_index :events, :event_type

    # ─── EVENT BOOKMARKS (members saving events) ────────────────
    create_table :event_bookmarks do |t|
      t.references :user,   null: false, foreign_key: true
      t.references :event,  null: false, foreign_key: true
      t.timestamps
    end
    add_index :event_bookmarks, [:user_id, :event_id], unique: true

    # ─── MENU CATEGORIES ────────────────────────────────────────
    create_table :menu_categories do |t|
      t.string  :name,      null: false
      t.string  :menu_type, null: false, default: "food"
      t.integer :position,  default: 0
      t.boolean :active,    default: true
      t.timestamps
    end

    # ─── MENU ITEMS ─────────────────────────────────────────────
    create_table :menu_items do |t|
      t.references :menu_category, null: false, foreign_key: true
      t.string   :name,            null: false
      t.text     :description
      t.decimal  :price,           precision: 10, scale: 2
      t.string   :image_url
      t.boolean  :available,       default: true
      t.integer  :position,        default: 0
      t.timestamps
    end

    # ─── MENU PDFS ──────────────────────────────────────────────
    create_table :menu_pdfs do |t|
      t.string  :title,     null: false
      t.string  :pdf_type,  default: "food"
      t.string  :file_url,  null: false
      t.boolean :active,    default: true
      t.timestamps
    end

    # ─── MEDIA / GALLERY ────────────────────────────────────────
    create_table :media_items do |t|
      t.string     :title
      t.string     :media_type,   default: "image"
      t.string     :file_url,     null: false
      t.string     :thumbnail_url
      t.references :branch,       foreign_key: true
      t.boolean    :featured,     default: false
      t.integer    :position,     default: 0
      t.timestamps
    end

    # ─── NOTIFICATIONS ──────────────────────────────────────────
    create_table :notifications do |t|
      t.references :user,         null: false, foreign_key: true
      t.string     :title,        null: false
      t.text       :body
      t.string     :notif_type,   default: "info"
      t.boolean    :read,         default: false
      t.string     :link
      t.timestamps
    end

    # ─── SITE SETTINGS ──────────────────────────────────────────
    create_table :site_settings do |t|
      t.string :key,   null: false
      t.text   :value
      t.string :group, default: "general"
      t.timestamps
    end
    add_index :site_settings, :key, unique: true

    # ─── AUDIT LOGS ─────────────────────────────────────────────
    create_table :audit_logs do |t|
      t.references :user,       foreign_key: true
      t.string     :action,     null: false
      t.string     :resource
      t.integer    :resource_id
      t.text       :details
      t.string     :ip_address
      t.timestamps
    end

  end
end