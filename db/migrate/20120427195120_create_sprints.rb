class CreateSprints < ActiveRecord::Migration
  def self.up
    create_table :sprints do |t|
      t.column :id, :integer
      t.column :starts_on, :date
      t.column :ends_on, :date
      t.column :name, :string
    end
  end

  def self.down
    drop_table :sprints
  end
end
