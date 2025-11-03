class AddStripeFieldsToSubscriptions < ActiveRecord::Migration[7.2]
  def up
    add_column :subscriptions, :cancel_at_period_end, :boolean, default: false
    add_index :subscriptions, :stripe_customer_id
  end

  def down
    remove_index :subscriptions, :stripe_customer_id, if_exists: true
    remove_column :subscriptions, :cancel_at_period_end, if_exists: true
  end
end
