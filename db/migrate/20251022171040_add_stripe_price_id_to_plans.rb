class AddStripePriceIdToPlans < ActiveRecord::Migration[7.2]
  def up
    add_column :plans, :stripe_price_id, :string
    add_index  :plans, :stripe_price_id
  end

  def down
    remove_index  :plans, :stripe_price_id, if_exists: true
    remove_column :plans, :stripe_price_id, if_exists: true
  end
end
