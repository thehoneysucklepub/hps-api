# Websites allowed to call the API from the browser.
# Extra origins (e.g. a Vercel preview URL) can be added on Render without a code
# change: CORS_ORIGINS="https://hps-frontend-git-xyz.vercel.app,https://other.example"
default_origins = [
  "https://www.honeysucklepub.com",
  "https://honeysucklepub.com",
  "http://localhost:5173",
  "http://127.0.0.1:5173"
]
extra_origins = ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*(default_origins + extra_origins).uniq)

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
