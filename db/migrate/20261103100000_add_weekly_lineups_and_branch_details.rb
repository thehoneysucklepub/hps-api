# Additive only: no columns are removed or renamed, existing rows keep working.
class AddWeeklyLineupsAndBranchDetails < ActiveRecord::Migration[7.2]
  def change
    # ── Weekly line-ups ─────────────────────────────────────────
    # recurrence "none"   = one-off event (date_start / date_end, as before)
    # recurrence "weekly" = repeats every week on days_of_week ("5" = Friday, "1,2,3" = Mon–Wed)
    add_column :events, :recurrence,   :string, null: false, default: "none"
    add_column :events, :days_of_week, :string          # 0 = Sunday … 6 = Saturday
    add_column :events, :time_end,     :string          # "03:00"; empty = "till late"
    add_column :events, :area,         :string          # "Main", "Smoking area", "Upstairs"…
    add_index  :events, :recurrence

    # ── Branch details for the venue pages ─────────────────────
    add_column :branches, :image_url,     :string       # cover photo
    add_column :branches, :tagline,       :string
    add_column :branches, :opening_hours, :text
    add_column :branches, :map_url,       :string
    add_column :branches, :venue_type,    :string, null: false, default: "pub"  # pub | bar | restaurant
    add_column :branches, :position,      :integer, null: false, default: 0
  end
end
