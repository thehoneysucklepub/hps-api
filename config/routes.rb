Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do

      # ── Auth ──────────────────────────────────────────
      post   "auth/login",    to: "auth#login"
      post   "auth/refresh",  to: "auth#refresh"
      delete "auth/logout",   to: "auth#logout"
      get    "auth/me",       to: "auth#me"

      # ── Users ─────────────────────────────────────────
      resources :users, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch :toggle_active
          get   :notifications
        end
      end

      # ── Branches ──────────────────────────────────────
      resources :branches, only: [:index, :show, :create, :update, :destroy]

      # ── Events ────────────────────────────────────────
      resources :events, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :live
          get :upcoming
          get :this_week
          get :featured
          get :weekly
        end
        member do
          patch :toggle_featured
          patch :update_status
        end
      end

      # ── Event Bookmarks ───────────────────────────────
      resources :event_bookmarks, only: [:index, :create, :destroy]

      # ── Menu ──────────────────────────────────────────
      resources :menu_categories, only: [:index, :show, :create, :update, :destroy] do
        resources :menu_items, only: [:index, :show, :create, :update, :destroy]
      end
      resources :menu_pdfs, only: [:index, :show, :create, :update, :destroy] do
        member do
          get  :file     # the PDF itself (?download=1 to download)
          post :fetch    # copy the PDF from its link (e.g. Google Drive) into the database
          post :upload   # replace the stored PDF (multipart "file")
        end
      end

      # ── Stored files (photos, PDFs kept in the database) ──
      resources :files, only: [:index, :create, :destroy]
      get "files/:id(/:name)", to: "files#show", as: :stored_file,
                               constraints: { id: /\d+/, name: %r{[^/]+} }

      # ── Media ─────────────────────────────────────────
      resources :media_items, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch :toggle_featured
        end
      end

      # ── Notifications ─────────────────────────────────
      resources :notifications, only: [:index, :show, :destroy] do
        member do
          patch :mark_read
        end
        collection do
          patch :mark_all_read
        end
      end

      # ── Site Settings ─────────────────────────────────
      resources :site_settings, only: [:index, :show, :create, :update] do
        collection do
          get :public, action: :public_settings   # read-only, no login: site name, social links, Bar-X copy
        end
      end

      # ── Audit Logs ────────────────────────────────────
      resources :audit_logs, only: [:index]

      # ── Dashboard Stats ───────────────────────────────
      get "dashboard/stats", to: "dashboard#stats"

      # ── Health Check ──────────────────────────────────
      get "health", to: "health#check"

      # ── Member Auth ───────────────────────────────────
      post "members/register",  to: "members#register"
      get  "members/profile",   to: "members#profile"
      put  "members/profile",   to: "members#update_profile"
      get  "members/dashboard", to: "members#dashboard"

      # ── Event Bookings ────────────────────────────────
      resources :event_bookings, only: [:index, :show, :create, :update, :destroy]

      # ── Table Reservations ────────────────────────────
      resources :table_reservations, only: [:index, :show, :create, :update, :destroy]

    end
  end
end