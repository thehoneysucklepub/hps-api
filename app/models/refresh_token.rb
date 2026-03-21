class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token,      presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked: false).where("expires_at > ?", Time.now) }

  def expired?
    expires_at < Time.now
  end

  def valid_token?
    !revoked && !expired?
  end
end