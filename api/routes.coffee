scraper = require './score_scraper'
attendance = require './attendance_scraper'
balancer = require './balance_algorithm'
async = require 'async'
roles = require './roles'
formula = require './formula'

@include = ->
	
	
	# this takes one list of players (or URL's), parses them to get their scores and then balances out the teams. Returns json as follows: {confidance: -ve % is favoured to team 0, teams: [[players in team with role],[players in team with role]]}
	@post '/balance-teams': (req, res) ->
		console.log '==== start balance-teams ===='
		console.log 'updating players'
		#we assume a player at this point has a preference array, a scraper url or manual score and a name
		scraper.updatePlayers req.body.players, (err, players) ->
			console.log 'balancing teams'
			result = balancer.balance players
			console.log roles.names
			for t in result.teams
				for player in t
					player.roleName = roles.names[player.preference[player.roleID]]
			console.log result
			console.log '==== Done ===='
			res.json 200, result
	
	#this takes in an array of teams [[players in team with role],[players in team with role]] and returns a % favourability towards one team or the other.
	@post '/score-teams': (req, res) ->
		async.parallel [ (callback) -> scraper.updatePlayers req.body.teams[0], callback
			, (callback) -> scraper.updatePlayers req.body.teams[1], callback
		], (err, teams) ->
			res.json 200, balancer.rateTeamBalanceConfidance teams
	
	@post '/balance-multi-teams': (req, res) ->
		scraper.getPlayers req.body.players, (err, players) ->
			scraper.getPlayers req.body.captains, (err, captains) ->
				result = balancer.multiteambalance players, captains
				res.json 200, result
	
	@on 'set_channel': ->
		# console.log "Setting Channel to #{@data.clan_name}"
		@leave(@client.room) if @client.room
		@client.room = @data.clan_name
		@join @client.room
	@on 'update-players': ->
		# console.log "Update Players"
		scraper.updatePlayers @data.players, (err, player) =>
			# console.log "Broadcast update done for #{player.name}  in #{@client.room}, clients in room: #{@io.sockets.clients(@client.room).length}"
			@broadcast_to @client.room, 'playerupdate', player
	
	@post '/api/get-attendance': (req, res) ->
		attendance.getAttendance "#{req.body.eventid}", req.body.username, req.body.password, (err, attending) ->
			if err then res.json 400, attending
			else res.json 200, attending
	
	@post '/api/test-formula': (req, res) ->
		tempaggregateFormula = formula.aggregateFormula
		formula.aggregateFormula = req.body.formula
		players = req.body.players
		for key, player of players
			formula.calculateAggregate player
		res.json 200, players
	
	@post '/api/save-formula': (req, res) ->
		formula.aggregateFormula = req.body.formula
		# need to recalc all the formulas at this point
	
	@get '/api/load-data': (req, res) ->
		# normally set during login
		#@session.static_data = 
		static_data = 
			clan_name: 'TAW LL5'
			players:
				p0:
					pid: 'p0'
					leader: true
					name: 'Xanetia'
					inGameName: 'Xan'
					server: 'oce'
					urls:
						opgg:
							root: 'http://oce.op.gg/summoner/'
							id: '345086'
						loldb: 'http://loldb.gameguyz.com/analyze/default/index/200090807/9/345086'
					scores:
						loldb: 3626
						opgg: 1142
						win: 4
						loss: 1
						aggregate: 4768
					rank:
						label: 'Silver V'
						ranktier: 6 
					preference: [ 1, 0, 4, 2, 3 ]
					mostPlayedChampions: [
						champion: 'Thresh'
						games: '15'
						kda: '2.76:1'
					,
						champion: 'Sivir'
						games: '13'
						kda: '3.45:1'
					,
						champion: 'Leona'
						games: '6'
						kda: '2.19:1'
					]
				p1:
					pid: 'p1'
					inGameName: 'NocturnalGannet'
					name: 'NocturnalGannet'
					server: 'oce'
					urls:
						opgg:
							root: 'http://oce.op.gg/summoner/'
							id: '330730'
						loldb: 'http://loldb.gameguyz.com/analyze/default/index/200082221/9/330730'
					scores: { loldb: 6828, opgg: 1629, win: 2, loss: 8, aggregate: 8457 }
					rank: { label: 'Gold V', ranktier: 11 }
					preference: [ 3, 0, 4, 1, 2 ]
					mostPlayedChampions:[
						{ champion: 'Renekton', games: '10', kda: '6.79:1' }
						{ champion: 'Dr. Mundo', games: '4', kda: '4.73:1' }
						{ champion: 'Cho\'Gath', games: '3', kda: '6.14:1' } 
					]
				p2:
					pid: 'p2'
					inGameName: 'Jesilicious'
					server: 'oce'
					urls:
						opgg: { root: 'http://oce.op.gg/summoner/', id: '1610200' }
						loldb: 'http://loldb.gameguyz.com/analyze/default/index/200802977/9/1610200'
					scores: { loldb: 1766, opgg: 0, win: 2, loss: 0, aggregate: 1766 }
					name: 'Jesilicious'
					rank: { label: 'Unranked', ranktier: 0 }
					preference: [ 1, 4, 3, 2, 0 ]
					mostPlayedChampions: [
						{ champion: 'Kha\'Zix', games: '7', kda: '2.40:1' }
						{ champion: 'Malphite', games: '2', kda: '4.40:1' }
						{ champion: 'Gragas', games: '1', kda: '0.00:1' }
					]
				p3:
					pid: 'p3'
					server: 'oce'
					name: 'ShawnAdriel'
					inGameName: 'ShawnAdriel'
					updatingerror: "Error Occured Updating LOLDB profile"
			sessions:
				s0:
					name: 'session1'
					teams: 
						t0:
							name: 'team1'
							players: ['p0']
							win: 3
							loss: 2
						t1:
							name: 'team2'
							leader: 'p1'
							players: ['p1','p2']
							win: 2
							loss: 3
					playerTeamMatrix:
						p0:
							t0:
								against:
									win: 0
									loss: 3
								with:
									win: 1
									loss: 0
							t1:
								against:
									win: 0
									loss: 3
								with:
									win: 1
									loss: 0
						p1:
							t1:
								against:
									win: 0
									loss: 3
								with:
									win: 1
									loss: 0
					defaultPairings: [
						['t0','t1']
					]
					history: [
						date: 'tuesday'
						pairings: [
							team1:
								id: 't0'
								name: 'team1'
								players: ['p0','p2']
							team2:
								id: 't1'
								name: 'team2'
								players: ['p1']
							winner: 1 #either 1 or 2, 0 for inprogress
						]
					,
						date: 123423531365134
						pairings: [
							team1:
								id: 't0'
								name: 'team1'
								players: ['p0']
							team2: undefined #this means against "randoms" or the Riot Queue
							winner: 2
						,
							team1:
								id: 't1'
								name: 'team2'
								players: ['p1']
							team2: undefined
							winner: 1 #either 1 or 2, 0 for inprogress
						]
					,
						date: 'Saturday'
						pairings: [
							team1:
								id: 't1'
								name: 'team2'
								players: ['p1','p0','p2']
							team2: undefined #this means against "randoms" or the Riot Queue
							winner: 2
						]
					]
		#res.json 200, @session.static_data
		res.json 200, static_data