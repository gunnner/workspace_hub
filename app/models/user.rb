class User < ApplicationRecord
  include User::RansackWhitelist

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :projects, foreign_key: :created_by_id, dependent: :nullify

  validates :email,      presence: true, uniqueness: { case_sensitive: false }
  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :api_token, uniqueness: true, allow_nil: true

  before_create :generate_api_token

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  def regenerate_api_token!
    update!(api_token: generate_token)
  end

  def member_of?(organization)
    organizations.include?(organization)
  end

  def role_in(organization)
    memberships.find_by(organization: organization)&.role
  end

  def owner_of?(organization)
    memberships.find_by(organization: organization)&.owner?
  end

  def admin_of?(organization)
    memberships.find_by(organization: organization)&.admin?
  end

  def can_manage_billing_for?(organization)
    owner_of?(organization)
  end

  private

  def generate_api_token
    self.api_token ||= generate_token
  end

  def generate_token
    loop do
      token = SecureRandom.urlsafe_base64(32)

      break token unless User.exists?(api_token: token)
    end
  end
end
