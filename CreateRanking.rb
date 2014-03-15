class CreateRanking < ActiveRecord::Migration
	def change
		create_table :ranking do |t|
			t.string :name
			t.string :path
			t.double :causal_mmr
			t.double :mmr
		end
	end
end