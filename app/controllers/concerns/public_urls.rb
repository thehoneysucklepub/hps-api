# Helpers for building public file links and serving stored files.
module PublicUrls
  extend ActiveSupport::Concern

  private

  # Public address of the API ending in /api/v1.
  # Set PUBLIC_API_URL (e.g. https://api.honeysucklepub.com) if links come out wrong behind a proxy.
  def api_base_url
    root = ENV["PUBLIC_API_URL"].presence || request.base_url
    "#{root.chomp('/')}/api/v1"
  end

  # True when the request carries a valid staff/admin token (does not raise)
  def admin_request?
    token = extract_token
    return false unless token

    payload = JsonWebToken.decode(token)
    user = User.find_by(id: payload[:user_id])
    user.present? && user.active? && user.can_manage?
  rescue StandardError
    false
  end

  # immutable: true when the address itself changes with each new upload
  # (/files/:id, or ?v=<file id>); otherwise browsers re-check after 5 minutes.
  def send_stored(stored, download: false, filename: nil, immutable: true)
    response.headers["Cache-Control"] = immutable ? "public, max-age=31536000, immutable" : "public, max-age=300"
    response.headers["X-Content-Type-Options"] = "nosniff"
    send_data stored.data,
              type: stored.content_type,
              disposition: download ? "attachment" : "inline",
              filename: filename || stored.filename
  end
end
