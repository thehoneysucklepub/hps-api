# Loads the client's content (Nov 2026):
#   - weekly line-ups for every branch
#   - the Borracha and Bar-X venues (Bar-X with its original page content)
#   - the food and drinks menus, copied from Google Drive into the database
#
#   bin/rails hps:content      everything below
#   bin/rails hps:menus        only (re)copy the menu PDFs from their links
#
# Safe to re-run: venues are matched by slug, line-up entries by
# branch + title + days + area, menus by their Drive file; fields that staff
# have already filled in are never overwritten and nothing is deleted.
# Everything here can be edited afterwards in the admin.
#
# Day numbers: 0 = Sunday, 1 = Monday … 6 = Saturday.
namespace :hps do
  # Current menus (Google Drive, shared "Anyone with the link")
  MENU_LINKS = [
    { title: "Food Menu",   pdf_type: "food",   position: 0,
      file_url: "https://drive.google.com/file/d/1VTn2zTa2AtX7wZLv3UwGmaNA6-qM6X-H/view" },
    { title: "Drinks Menu", pdf_type: "drinks", position: 1,
      file_url: "https://drive.google.com/file/d/1UQQnFlLfeOrDIdyCw-4WY9WkFbnFVMNS/view" }
  ].freeze

  # Bar-X page as it was on the previous website (reservation buttons removed:
  # bookings are no longer offered). Editable in Admin → Branches → Bar-X.
  BAR_X_PAGE = {
    tagline:     "Where sophistication meets celebration",
    eyebrow:     "Premium experience · The Honeysuckle Pub",
    description: "A premium destination redefining nightlife in Accra. Crafted for those who appreciate the finer things.",
    established_year: "2021",
    opening_hours: "Opens nightly from 7PM",
    story_title: "Born from a vision of extraordinary nights",
    story: "BAR X represents the evolution of nightlife culture in Accra, where traditional Honeysuckle " \
           "hospitality meets contemporary innovation. We've reimagined what it means to create spaces " \
           "for human connection.\n\nEvery element, from our handcrafted cocktails to our curated soundscape, " \
           "has been thoughtfully designed to transcend the ordinary.",
    stats: [
      { value: "50+",  label: "Signature cocktails" },
      { value: "500+", label: "Happy guests" },
      { value: "5★",   label: "Experience" },
      { value: "7PM",  label: "Opens nightly" }
    ],
    features: [
      { title: "Craft Cocktails",
        text: "Meticulously crafted beverages using premium spirits and fresh ingredients. Our master mixologists create signature cocktails that define modern elegance and timeless sophistication." },
      { title: "Ambient Atmosphere",
        text: "Immerse yourself in an environment designed for connection and conversation. Contemporary lighting and curated music create the perfect backdrop for memorable evenings." },
      { title: "Exceptional Service",
        text: "Our dedicated team ensures every visit exceeds expectations. From personalised recommendations to attentive hospitality, we are committed to creating extraordinary moments." },
      { title: "VIP Experience",
        text: "Make your special occasion your own. Our VIP packages include dedicated service, premium bottles and bespoke setups tailored to your celebration. Call us to arrange." },
      { title: "Live Entertainment",
        text: "Experience world-class live performances every weekend. From jazz to Afrobeats, our curated music programme sets the tone for an unforgettable night." },
      { title: "Premium Location",
        text: "Situated in the heart of Accra, BAR X is easily accessible and surrounded by the city's most vibrant energy. The perfect destination for any occasion." }
    ],
    signatures_title: "Signature cocktails",
    signatures: [
      { name: "X Noir",        text: "Aged rum, blackberry, activated charcoal, citrus foam", price: "85" },
      { name: "Gold Rush",     text: "Bourbon, honey, lemon, gold leaf garnish",              price: "90" },
      { name: "Violet Dreams", text: "Gin, butterfly pea flower, elderflower, tonic",         price: "80" },
      { name: "Neon Tropics",  text: "Coconut rum, mango, lime, neon sugar rim",              price: "75" },
      { name: "The Crimson",   text: "Premium vodka, blood orange, hibiscus, prosecco",       price: "95" },
      { name: "Midnight Star", text: "Silver tequila, smoky mezcal, agave, chilli salt",      price: "85" }
    ]
  }.freeze

  desc "Copy the menu PDFs from their links (Google Drive) into the database"
  task menus: :environment do
    MENU_LINKS.each do |m|
      drive_id = RemotePdf.drive_id(m[:file_url])
      exists = MenuPdf.where.not(file_url: nil).any? { |p| RemotePdf.drive_id(p.file_url) == drive_id }
      next if exists

      MenuPdf.create!(m.merge(active: true))
      puts "+ menu #{m[:title]}"
    end

    MenuPdf.active.where(stored_file_id: nil).where.not(file_url: nil).find_each do |pdf|
      print "  copying #{pdf.title} from its link… "
      file = pdf.store_from_link!
      puts "ok (#{(file.byte_size / 1024.0 / 1024).round(1)} MB)"
    rescue RemotePdf::Error => e
      puts "not copied: #{e.message}"
      puts "    The website still shows it from the link. Retry later with: bin/rails hps:menus,"
      puts "    or upload the PDF in Admin → Menu → Menu PDFs."
    end
  end

  desc "Load weekly line-ups, Borracha / Bar-X venues and the menus"
  task content: :environment do
    # ── New venues (details to be completed in Admin → Branches) ──────────
    # Borracha: address and phone from its public listing (La Borracha, Labone).
    {
      "borracha" => { name: "Borracha", venue_type: "bar", position: 50,
                      address: "11 Dade Street, Labone", phone_primary: "0548290039" },
      "bar-x"    => { name: "Bar-X",    venue_type: "bar", position: 60 }
    }.each do |slug, attrs|
      branch = Branch.find_or_initialize_by(slug: slug)
      if branch.new_record?
        branch.assign_attributes(attrs.merge(active: true))
        branch.save!
        puts "+ venue #{branch.name}"
      else
        # fill only fields that are still empty
        missing = attrs.select { |k, v| branch[k].blank? && v.present? }
        branch.update!(missing) if missing.any?
      end
    end

    # ── Branch details as printed on the current menu PDF (client: PDF is correct) ──
    {
      "east-legon" => { established_year: "2014" },
      "spintex"    => { established_year: "2023", phone_primary: "0531100401" }
    }.each do |slug, attrs|
      branch = Branch.find_by(slug: slug)
      next unless branch
      changed = attrs.reject { |k, v| branch[k] == v }
      next if changed.empty?
      branch.update!(changed)
      puts "~ #{branch.name}: #{changed.keys.join(', ')}"
    end

    # Bar-X page content: fill only what staff have not filled in yet
    if (barx = Branch.find_by(slug: "bar-x"))
      missing = BAR_X_PAGE.select do |k, v|
        current = barx[k]
        current.blank? || (current.is_a?(Array) && current.empty?) ? v.present? : false
      end
      if missing.any?
        barx.update!(missing.transform_values { |v| v.is_a?(Array) ? v.map(&:stringify_keys) : v })
        puts "~ Bar-X page: #{missing.keys.join(', ')}"
      end
    end

    # Instagram as printed on the menu: @the.honeysuckle
    SiteSetting.set("instagram_url", "https://instagram.com/the.honeysuckle", group: "social")

    # ── Weekly line-ups as sent by the client ─────────────────────────────
    # t: title, d: days, s: start "HH:MM", e: end "HH:MM", a: area, b: badge, type: lineup|promo
    lineups = {
      # "Legon" in the client's list = East Legon (A & C Mall), confirmed.
      "east-legon" => [
        { t: "DJ Blinki",    d: "5", s: "21:00", e: "03:00", a: "Main area",    b: "DJ" },
        { t: "DJ Banger",    d: "5", s: "21:00", e: "03:00", a: "Smoking area", b: "DJ" },
        { t: "Karaoke Night", d: "6", s: "21:00", e: "03:00", a: "Main and smoking area", b: "Karaoke",
          desc: "With the karaoke team." },
        { t: "DJ Blinki",    d: "0", s: "21:00", e: "03:00", b: "DJ" }
      ],
      "labone" => [
        { t: "DJ Endow & DJ Rector",     d: "5", b: "DJs" },
        { t: "DJ Bass & DJ Benny Moore", d: "6", b: "DJs" }
      ],
      "osu" => [
        { t: "Live Band by Tyme",                    d: "4", a: "Upstairs",   b: "Live band" },
        { t: "DJ Benny More",                        d: "4", a: "Downstairs", b: "DJ" },
        { t: "DJ Benny More & Crazy Fingers",        d: "5", b: "DJs" },
        { t: "Intercontinental Music with DJ K-Don", d: "6", b: "DJ" },
        { t: "Live Band by Tyme",                    d: "0", a: "Upstairs",   b: "Live band" },
        { t: "DJ Benny More",                        d: "0", b: "DJ" }
      ],
      "airport" => [
        { t: "Live Music by Tyme",      d: "3", s: "19:00", e: "22:00", b: "Live music" },
        { t: "Sing and Spin (Karaoke)", d: "5", s: "21:00", e: "00:00", b: "Karaoke" },
        { t: "DJ Vendetta",             d: "5", s: "00:00", e: "03:00", b: "DJ" },
        { t: "DJ Natty",                d: "6", s: "19:00", e: "22:00", b: "DJs Night" },
        { t: "DJ MJ",                   d: "6", s: "22:00", e: "03:00", b: "DJs Night" },
        { t: "DJ Bella",                d: "0", s: "19:00", e: "22:00", b: "Playlist Party" },
        { t: "DJ Natty",                d: "0", s: "22:00", e: "03:00", b: "Playlist Party" }
      ],
      "spintex" => [
        { t: "Karaoke",                          d: "5", s: "21:00", e: "23:00", b: "Karaoke" },
        # Client wrote "11pm to 12pm" = 11PM to midnight, confirmed.
        { t: "DJ Loft",                          d: "5", s: "23:00", e: "00:00", b: "DJ" },
        { t: "Various DJs and MCs on rotation",  d: "5", b: "DJs" },
        { t: "DJs Night with various DJs",       d: "6", b: "DJs Night" }
      ],
      "borracha" => [
        { t: "Happy Hour", d: "1,2,3", s: "17:00", e: "19:00", b: "Offer", type: "promo",
          desc: "Buy one get one free on selected cocktails." },
        { t: "Taco Tuesday", d: "2", b: "Offer", type: "promo",
          desc: "20% off all tacos and tostadas, all day." },
        { t: "Games Night after party with Crakk DJ", d: "4", b: "DJ" },
        { t: "Saoco with Julio Puig de Cuba", d: "5", b: "Live performance",
          desc: "Live performances by Julio Puig de Cuba." },
        { t: "Reggaeton after party with Crakk DJ", d: "5", b: "DJ" },
        { t: "Crakk DJ", d: "6", b: "DJ" }
      ]
    }

    created = 0
    lineups.each do |slug, items|
      branch = Branch.find_by(slug: slug)
      unless branch
        puts "! branch '#{slug}' not found, skipped"
        next
      end
      items.each_with_index do |i, idx|
        event = Event.find_or_initialize_by(
          branch_id: branch.id, title: i[:t], days_of_week: i[:d], area: i[:a], recurrence: "weekly"
        )
        next unless event.new_record?

        event.assign_attributes(
          event_type:  i[:type] || "lineup",
          badge:       i[:b],
          description: i[:desc],
          time_local:  i[:s],
          time_end:    i[:e],
          date_start:  Date.today,
          status:      "scheduled",
          priority:    100 - idx,
          source:      "client_lineup_2026_11",
        )
        event.save!
        created += 1
      end
    end
    puts "+ #{created} weekly line-up entries"

    Rake::Task["hps:menus"].invoke
  end
end
