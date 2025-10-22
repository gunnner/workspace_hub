class Task
  module RansackWhitelist
    extend ActiveSupport::Concern

    included do
      def self.ransackable_attributes(auth_object = nil)
        %w[id title description status project_id organization_id completed_at created_at updated_at]
      end

      def self.ransackable_associations(auth_object = nil)
        %w[project organization]
      end
    end
  end
end
