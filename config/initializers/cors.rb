Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("FRONTEND_URL") { "http://localhost:5173, https://honeysucklepub.com, https://www.honeysucklepub.com" }

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["Authorization"],
      max_age: 600,
      credentials: false
  end
end