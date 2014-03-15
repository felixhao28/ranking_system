class CreateRankings < ActiveRecord::Migration
  def change
    create_table :rankings do |t|
      t.string :name
      t.string :path
      t.decimal :casual_mmr
      t.decimal :mmr

      t.timestamps
    end
  end
end
