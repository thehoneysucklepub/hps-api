class User < ApplicationRecord
  has_secure_password

  belongs_to :branch, optional: true
  has_many :refresh_tokens, dependent: :destroy
  has_many :event_bookmarks, dependent: :destroy
  has_many :bookmarked_events, through: :event_bookmarks, source: :event
  has_many :notifications, dependent: :destroy
  has_many :event_bookings,     dependent: :destroy
  has_many :table_reservations, dependent: :destroy
  has_one  :member_profile,     dependent: :destroy

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: %w[super_admin admin staff member] }

  scope :active, -> { where(active: true) }
  scope :admins, -> { where(role: %w[super_admin admin]) }

  def super_admin? = role == "super_admin"
  def admin?       = role == "admin"
  def staff?       = role == "staff"
  def member?      = role == "member"
  def can_manage?  = %w[super_admin admin staff].include?(role)
    

  def full_name
    [first_name, last_name].compact.join(" ").presence || username
  end
end