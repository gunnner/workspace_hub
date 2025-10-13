class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def up
    create_table :subscriptions do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :plan,         null: false, foreign_key: true
      t.integer    :status,       null: false, default: 0
      t.datetime   :trial_ends_at
      t.datetime   :current_period_start
      t.datetime   :current_period_end
      t.datetime   :canceled_at
      t.text       :cancellation_reason
      t.string     :stripe_subscription_id
      t.string     :stripe_customer_id

      t.timestamps
    end

    add_index :subscriptions, :status
    add_index :subscriptions, :stripe_subscription_id, unique: true
    add_index :subscriptions, %i[organization_id status]
  end

  def down
    drop_table :subscriptions, if_exists: true
  end
end
