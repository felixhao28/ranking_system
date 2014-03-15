class PostsController < ApplicationController
	def new
	end

	def create
		@ranking = registerUser(params[:post][:username],params[:post][:path])
		render text: @ranking.inspect
	end

	def match_normal
		@result = match(params[:id],false)
		render text: @result.inspect
	end

	def match_casual
		@result = match(params[:id],true)
		render text: @result.inspect
	end

	def game_end_casual
		@result = updateMMR(params[:winner],[params[:loser0],params[:loser1],params[:loser2]],true)
		render text: @result.inspect
	end

	def game_end_normal
		@result = updateMMR(params[:winner],[params[:loser0],params[:loser1],params[:loser2]],false)
		render text: @result.inspect
	end
#returns 3 names and 3 paths. e.g. [["felix","./felix.js"],["seiji","./seiji.js"],["sakamoto","./saka.rb"]]
	def match _name, _casualMode
		if _casualMode
			#execute "select casual_mmr from ranking where name=#{_name}"
			#result as 'mmr'
			mmr = Ranking.find(_name).casual_mmr
			#execute "select path from ranking where name<>#{_name} order by abs(casual_mmr-#{mmr}) asc limit 3"
			#result as '_path'
			query = Ranking.where.not("name==\"#{_name}\"").order("abs(casual_mmr-(#{mmr}))").first(3)
			ret = []
			query.each{|x| ret.push([x.name,x.path])}
		else
			#execute "select mmr from ranking where name=#{_name}"
			#result as 'mmr'
			mmr = Ranking.find(_name).mmr
			#execute "select path from ranking where name<>#{_name} order by abs(mmr-#{mmr}) asc limit 3"
			#result as 'path'
			query = Ranking.where.not("name==\"#{_name}\"").order("abs(mmr-(#{mmr}))").first(3)
			ret = []
			query.each{|x| ret.push([x.name,x.path])}
		end
		if _casualMode
			print("casual mode:")
		end
		puts("match #{_name} with #{ret}")
		return ret 
	end

	# Called upon finishing a game. Returns new MMR's, first element in the array is winner. e.g. [['felixh',2.3],['saka',1.2],['seiji',3.1],['hiro',0.0]].
	def updateMMR _winner, _losers, _casualMode
		if _casualMode
			alias updatemmr updateCasualMMR
			#execute "select casual_mmr from ranking where name=#{_name}"
			#result as 'w_mmr'
			w_mmr = Ranking.find(_winner).casual_mmr
			#execute "select distinct name,casual_mmr from ranking where name in (#{losers[0]}, #{losers[1]}, #{losers[2]})"
			rec = Ranking.where(name: _losers).distinct
			#update mmr using modified ELO ranking for multiple players
			#http://forum.unity3d.com/threads/81579-ELO-ratings-for-multiplayer-game
			#for winner
			puts(rec.inspect)
			sum = 0
			rec.each do |r|
				sum = sum + 25*(1-GetExpectedScore(w_mmr, r.casual_mmr))
			end
			ret=[]
			updatemmr(_winner,w_mmr+sum)
			ret.push([_winner,w_mmr+sum])
			#for each loser
			rec.each do |r|
				sum = 0
				name=r.name
				mmr=r.casual_mmr
				rec.each do |r2|
					if name!=r2.name
						sum = sum + 25*(0.5-GetExpectedScore(mmr, r2.casual_mmr))
					end
				end
				sum = sum + 25*(-GetExpectedScore(mmr,w_mmr))
				updatemmr(name, mmr+sum)
				ret.push([name,mmr+sum])
			end
		else
			alias updatemmr updateRankedMMR
			#execute "select mmr from ranking where name=#{_name}"
			#result as 'w_mmr'
			w_mmr = Ranking.find(_winner).mmr
			#execute "select distinct name,mmr from ranking where name in (#{losers[0]}, #{losers[1]}, #{losers[2]})"
			rec = Ranking.where(name: _losers).distinct
			#update mmr using modified ELO ranking for multiple players
			#http://forum.unity3d.com/threads/81579-ELO-ratings-for-multiplayer-game
			#for winner
			puts(rec.inspect)
			sum = 0
			rec.each do |r|
				sum = sum + 25*(1-GetExpectedScore(w_mmr, r.mmr))
			end
			ret=[]
			updatemmr(_winner,w_mmr+sum)
			ret.push([_winner,w_mmr+sum])
			#for each loser
			rec.each do |r|
				sum = 0
				name=r.name
				mmr=r.mmr
				rec.each do |r2|
					if name!=r2.name
						sum = sum + 25*(0.5-GetExpectedScore(mmr, r2.mmr))
					end
				end
				sum = sum + 25*(-GetExpectedScore(mmr,w_mmr))
				updatemmr(name, mmr+sum)
				ret.push([name,mmr+sum])
			end
		end
		return ret	
	end

	def registerUser _name, _path
		#execute "insert into ranking values(#{_name},#{_path},0,0)"
		@ranking = Ranking.new(name:_name, path:_path, casual_mmr:0, mmr:0)
		@ranking.save
		return @ranking
#		Ranking.create(name:_name, path:_path, casual_mmr:0, mmr:0)
#		Ranking.save
	end

	protected
		def GetExpectedScore rp, ro
			#puts("rp=#{rp.inspect};ro=#{ro.inspect}")
			1/(1+10.0**((rp-ro)/400.0))
		end
		

		def updateCasualMMR _name, _value
			#execute "update casual_mmr=#{_value} FROM ranking WHERE name == #{_name}"
			rec = Ranking.find(_name)
			rec.casual_mmr = _value
			rec.save
		end

		def updateRankedMMR _name, _value
			#execute "update mmr=#{_value} FROM ranking WHERE name == #{_name}"
			rec = Ranking.find(_name)
			rec.mmr = _value
			rec.save
		end
end
