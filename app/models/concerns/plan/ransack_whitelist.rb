class Plan
  module RansackWhitelist
    extend ActiveSupport::Concern

    included do
      def self.ransackable_attributes(auth_object = nil)
        %w[id name slug price_cents interval max_projects max_users max_storage_mb archived api_access priority_support created_at updated_at]
      end

      def self.ransackable_associations(auth_object = nil)
        %w[subscriptions]
      end
    end
  end
end
