class Organization
  module RansackWhitelist
    extend ActiveSupport::Concern

    included do
      def self.ransackable_attributes(auth_object = nil)
        %w[id name subdomain created_at updated_at]
      end

      def self.ransackable_associations(auth_object = nil)
        %w[users memberships projects tasks subscription plan]
      end
    end
  end
end
