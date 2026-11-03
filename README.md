# Honeysuckle Pub API (Rails)

JSON API for honeysucklepub.com. Rails 7.2, PostgreSQL (Supabase), deployed on Render.
Base URL: `https://api.honeysucklepub.com/api/v1`

## Deploying this update (Render + Supabase)

1. Push to the branch Render deploys from.
2. **Migrations run by themselves**: on start-up the server runs `bin/rails db:prepare`.
   The two new migrations only **add** tables and columns; nothing is removed:
   - `20261103100000`: weekly line-ups; venue photo, hours, map, type and order
   - `20261103120000`: `stored_files` table (menu PDFs and photos kept in the database);
     venue page sections; menus can be upload-only
3. **Load the client's content once** (line-ups, Borracha, Bar-X page, menus copied from Google Drive):
   - Render → your service → Environment → add `HPS_LOAD_CONTENT` = `true` → Save (it redeploys).
   - Check the deploy log for lines like `+ 29 weekly line-up entries` and `copying Food Menu … ok`.
   - Then **delete** `HPS_LOAD_CONTENT` (otherwise line-ups that staff delete would come back).
   - With a Render shell you can instead run `bin/rails hps:content` once.
4. Optional env vars:
   - `CORS_ORIGINS`: extra sites allowed to call the API (comma-separated), e.g. a Vercel preview URL.
   - `PUBLIC_API_URL`: only if file links come out as `http://` (e.g. `https://api.honeysucklepub.com`).

Required env vars (already set on Render): `DATABASE_URL`, `JWT_SECRET`, `RAILS_MASTER_KEY`.

**Nothing has to change in Supabase**: the migrations do it all. Stored PDFs and photos
count towards the Supabase database size (the free plan allows 500 MB; a menu PDF is usually 1–10 MB).

## Run on your computer

Needs Ruby 3.2 and PostgreSQL 14 or newer.

```bash
cp .env.example .env          # then fill in JWT_SECRET and your Postgres password
bundle install
bin/rails db:create db:migrate db:seed
bin/rails hps:content         # line-ups, Borracha, Bar-X page, copies the menus from Drive
bin/rails server -p 3002      # http://localhost:3002/api/v1/health
```

On Windows run the commands as `ruby bin/rails …`.
Seeded logins: `superadmin` / `HPS@Admin2026!` (change these passwords on the live site).

## Content tasks

| Command | What it does |
|---|---|
| `bin/rails hps:content` | Weekly line-ups, Borracha and Bar-X venues, Bar-X page content, branch details from the menu PDF, Instagram link, then `hps:menus`. Never duplicates or overwrites what staff filled in. |
| `bin/rails hps:menus` | Adds the Food/Drinks menus if missing (matched by their Drive file) and copies every menu that has no stored copy from its link into the database. |

## Menus (PDF)

Each menu has a link (Google Drive, shared "Anyone with the link") and/or a **stored copy** in the
database. The website shows the stored copy in its own PDF reader (works on phones) and downloads
it from the API. Without a stored copy it falls back to Google's viewer and the Drive download.

| Endpoint | Who | |
|---|---|---|
| `GET /menu_pdfs` | public | active menus in display order (`?all=true` with admin login: hidden ones too) |
| `GET /menu_pdfs/:id/file` | public | the PDF (`?download=1` to download); redirects to the link if not stored |
| `POST /menu_pdfs` | admin | JSON, or multipart with a `file`; `store_copy=true` copies from the link |
| `PUT /menu_pdfs/:id` | admin | same fields, optional `file` |
| `POST /menu_pdfs/:id/upload` | admin | multipart `file`: replace the stored PDF |
| `POST /menu_pdfs/:id/fetch` | admin | copy the PDF from its link now |

## Photos and files

`POST /files` (admin, multipart `file`, `purpose` = `photo` or `menu_pdf`) stores the file in the
database and returns its public `url` (`/api/v1/files/:id/:name`), used for venue cover photos and
Media items. JPG, PNG, WebP or GIF up to 8 MB; PDFs up to 25 MB. The type is checked from the
file's contents. Render's own disk is wiped on every deploy, which is why files live in the database.

## What the public website uses

| Endpoint | Used for |
|---|---|
| `GET /site_settings/public` | site name, tagline, Instagram |
| `GET /branches`, `GET /branches/:id-or-slug` | venues and their page content |
| `GET /events/weekly?branch_id=` | weekly line-ups, Monday → Sunday, late sets last |
| `GET /events/upcoming` | one-off events |
| `GET /menu_pdfs`, `GET /menu_pdfs/:id/file`, `GET /menu_categories` | menus |
| `GET /media_items?branch_id=`, `GET /files/:id/:name` | photos |

### Venue fields (branches)
`image_url` (cover photo), `tagline`, `description`, `opening_hours` (one line each), `map_url`,
`venue_type` (`pub` | `bar` | `restaurant`), `position` (display order), and optional page sections:
`eyebrow`, `story_title`, `story`, `stats` `[{value,label}]`, `features` `[{title,text}]`,
`signatures_title`, `signatures` `[{name,text,price}]`.

### Weekly line-up fields (events)
- `recurrence`: `none` (one-off, uses `date_start`) or `weekly`
- `days_of_week`: `"5"` = Friday, `"1,2,3"` = Mon–Wed (0 = Sunday … 6 = Saturday)
- `time_local` / `time_end`: `"21:00"` / `"03:00"`; empty = "Times TBC"
- `area`, `badge`, `event_type` (`lineup`, `promo`, `special`, `match`)

## Not used by the website any more
Bookings, table reservations, member accounts and bookmarks were removed from the website at the
client's request. Their endpoints and tables are left in place (no data deleted).
