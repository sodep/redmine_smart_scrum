class CreateBurndownData < ActiveRecord::Migration
  def self.up
    create_table :burndown_data do |t|
      t.column :id, :integer
      t.column :query_date, :date
      t.column :sprint, :string
      t.column :responsible, :string
      t.column :remaining_hours, :integer
    end
  end

  def self.down
    drop_table :burndown_data
  end
end
