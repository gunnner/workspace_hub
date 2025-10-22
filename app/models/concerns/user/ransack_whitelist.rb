class User
  module RansackWhitelist
    extend ActiveSupport::Concern

    included do
      def self.ransackable_attributes(auth_object = nil)
        %w[id email first_name last_name created_at updated_at current_sign_in_at last_sign_in_at sign_in_count]
      end

      def self.ransackable_associations(auth_object = nil)
        %w[organizations memberships projects]
      end
    end
  end
end
