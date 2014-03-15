class Ranking < ActiveRecord::Base

	self.table_name = "rankings"
	self.primary_key = "name"
end
