class Project
  module RansackWhitelist
    extend ActiveSupport::Concern

    included do
      def self.ransackable_attributes(auth_object = nil)
        %w[id name description status organization_id created_by_id created_at updated_at]
      end

      def self.ransackable_associations(auth_object = nil)
        %w[organization created_by tasks]
      end
    end
  end
end
