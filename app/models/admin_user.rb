class AdminUser < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable

  def self.ransackable_attributes(auth_object = nil)
    %w[id email created_at updated_at current_sign_in_at last_sign_in_at sign_in_count]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
