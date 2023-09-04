class AddColumnToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :history_id, :integer
    add_column :users, :queue_id, :integer
  end
end
