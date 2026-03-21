class AddReservationsAndMemberFeatures < ActiveRecord::Migration[7.2]
  def change

    # ── Event Bookings (member reserves spot at event) ────────
    create_table :event_bookings do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :event,    null: false, foreign_key: true
      t.references :branch,   null: false, foreign_key: true
      t.integer    :guests,   default: 1
      t.string     :status,   default: "pending"
      t.text       :notes
      t.string     :confirmation_code, null: false
      t.datetime   :confirmed_at
      t.datetime   :cancelled_at
      t.timestamps
    end
    add_index :event_bookings, :confirmation_code, unique: true
    add_index :event_bookings, [:user_id, :event_id]

    # ── Table Reservations (member books a table) ─────────────
    create_table :table_reservations do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :branch,   null: false, foreign_key: true
      t.date       :date,     null: false
      t.string     :time,     null: false
      t.integer    :guests,   null: false, default: 2
      t.string     :status,   default: "pending"
      t.text       :notes
      t.string     :occasion
      t.string     :confirmation_code, null: false
      t.datetime   :confirmed_at
      t.datetime   :cancelled_at
      t.timestamps
    end
    add_index :table_reservations, :confirmation_code, unique: true

    # ── Member Profiles (extra info for members) ──────────────
    create_table :member_profiles do |t|
      t.references :user,          null: false, foreign_key: true
      t.date       :date_of_birth
      t.string     :favorite_branch
      t.string     :preferred_sports
      t.text       :bio
      t.boolean    :notifications_enabled, default: true
      t.boolean    :marketing_emails,      default: false
      t.timestamps
    end

  end
end