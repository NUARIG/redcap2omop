class CreateOmopTables < ActiveRecord::Migration[6.0]
  def change
    create_table :omop_tables do |t|
      t.string :domain,       null: true
      t.string :name,         null: false
      t.timestamps
      t.datetime :deleted_at, null: true
    end
  end
end
