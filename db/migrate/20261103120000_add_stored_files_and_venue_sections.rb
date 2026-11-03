# Files (menu PDFs, photos) are kept in the database so they survive
# Render redeploys (Render's disk is wiped on every deploy).
# Venue pages get optional sections editable in Admin → Branches.
# Additive only: nothing is removed or renamed.
class AddStoredFilesAndVenueSections < ActiveRecord::Migration[7.2]
  def change
    create_table :stored_files do |t|
      t.string  :filename,     null: false
      t.string  :content_type, null: false
      t.integer :byte_size,    null: false
      t.string  :checksum,     null: false
      t.binary  :data,         null: false
      t.string  :purpose # "menu_pdf", "photo"
      t.timestamps
    end
    add_index :stored_files, :checksum

    add_reference :menu_pdfs, :stored_file, foreign_key: { on_delete: :nullify }, null: true
    add_column :menu_pdfs, :position, :integer, null: false, default: 0
    # A menu can be an uploaded PDF with no outside link
    change_column_null :menu_pdfs, :file_url, true

    change_table :branches, bulk: true do |t|
      t.string :eyebrow                       # small line above the name
      t.string :story_title
      t.text   :story                         # blank line = new paragraph
      t.jsonb  :stats,      null: false, default: []  # [{value, label}]
      t.jsonb  :features,   null: false, default: []  # [{title, text}]
      t.jsonb  :signatures, null: false, default: []  # [{name, text, price}]
      t.string :signatures_title
    end
  end
end
