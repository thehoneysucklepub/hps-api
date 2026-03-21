puts "Seeding HPS database..."

# ── Branches ──────────────────────────────────────────────────
branches_data = [
  { name: "Osu",          slug: "osu",          address: "Opposite The Fire Station, Ring Road East", phone_primary: "0275556006", established_year: "2007" },
  { name: "East Legon",   slug: "east-legon",   address: "A & C Mall",                                phone_primary: "0245615128", established_year: "2016" },
  { name: "Labone",       slug: "labone",       address: "4th Dade Street",                           phone_primary: "0558007995", phone_secondary: "0279560000", established_year: "2018" },
  { name: "Airport",      slug: "airport",      address: "Shell Station, Opposite Alliance Française", phone_primary: "0551115522", phone_secondary: "0542015266", established_year: "2021" },
  { name: "Spintex",      slug: "spintex",      address: "New Melcom Mall",                           phone_primary: "0533110401", established_year: "2022" },
  { name: "East Legon Extension", slug: "east-legon-extension", address: "East Legon Extension", phone_primary: "0245615128", established_year: "2023" }
]

branches_data.each do |data|
  Branch.find_or_create_by(slug: data[:slug]) do |b|
    b.name             = data[:name]
    b.address          = data[:address]
    b.phone_primary    = data[:phone_primary]
    b.phone_secondary  = data[:phone_secondary]
    b.established_year = data[:established_year]
    b.active           = true
  end
end
puts "✓ #{Branch.count} branches created"

# ── Super Admin ───────────────────────────────────────────────
super_admin = User.find_or_create_by(username: "superadmin") do |u|
  u.email           = "admin@honeysucklepub.com"
  u.password        = "HPS@Admin2026!"
  u.role            = "super_admin"
  u.first_name      = "Super"
  u.last_name       = "Admin"
  u.active          = true
end
puts "✓ Super admin created: #{super_admin.username}"

# ── Admin User ────────────────────────────────────────────────
admin = User.find_or_create_by(username: "honeysucklepub") do |u|
  u.email      = "honeysucklepub@honeysucklepub.com"
  u.password   = "HPS@Admin2026!"
  u.role       = "admin"
  u.first_name = "Honeysuckle"
  u.last_name  = "Admin"
  u.active     = true
end
puts "✓ Admin created: #{admin.username}"

# ── Staff User ────────────────────────────────────────────────
staff = User.find_or_create_by(username: "honeysucklepub1") do |u|
  u.email      = "staff@honeysucklepub.com"
  u.password   = "HPS@Staff2026!"
  u.role       = "staff"
  u.first_name = "Staff"
  u.last_name  = "User"
  u.branch     = Branch.find_by(slug: "osu")
  u.active     = true
end
puts "✓ Staff created: #{staff.username}"

# ── Site Settings ─────────────────────────────────────────────
settings = [
  { key: "site_name",        value: "The Honeysuckle Pub",           group: "general" },
  { key: "site_tagline",     value: "Sports Bar, Pub & Restaurant",  group: "general" },
  { key: "instagram_url",    value: "https://instagram.com/thehoneysucklepub", group: "social" },
  { key: "booking_enabled",  value: "true",                          group: "features" },
  { key: "maintenance_mode", value: "false",                         group: "features" }
]

settings.each do |s|
  SiteSetting.find_or_create_by(key: s[:key]) do |setting|
    setting.value = s[:value]
    setting.group = s[:group]
  end
end
puts "✓ #{SiteSetting.count} site settings created"

puts ""
puts "═══════════════════════════════════════"
puts " HPS Database seeded successfully!"
puts "═══════════════════════════════════════"
puts " Super Admin: superadmin / HPS@Admin2026!"
puts " Admin:       honeysucklepub / HPS@Admin2026!"
puts " Staff:       honeysucklepub1 / HPS@Staff2026!"
puts "═══════════════════════════════════════"