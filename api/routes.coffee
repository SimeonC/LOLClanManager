scraper = require './score_scraper'
attendance = require './attendance_scraper'
balancer = require './balance_algorithm'
async = require 'async'
roles = require './roles'
formula = require './formula'

lolapi = require './../startup_security/leaguejs'
auth0 = require './../startup_security/auth0'
{admin_nano: _nano, nano} = require './../startup_security/nano'

static_data = {}

@include = ->
	# this takes one list of players (or URL's), parses them to get their scores and then balances out the teams. Returns json as follows: {confidance: -ve % is favoured to team 0, teams: [[players in team with role],[players in team with role]]}
	@post '/balance-teams', (req, res) ->
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
	@post '/score-teams', (req, res) ->
		async.parallel [ (callback) -> scraper.updatePlayers req.body.teams[0], callback
			, (callback) -> scraper.updatePlayers req.body.teams[1], callback
		], (err, teams) ->
			res.json 200, balancer.rateTeamBalanceConfidance teams
	
	@post '/balance-multi-teams', (req, res) ->
		scraper.getPlayers req.body.players, (err, players) ->
			scraper.getPlayers req.body.captains, (err, captains) ->
				result = balancer.multiteambalance players, captains
				res.json 200, result
	
	# query DB and see if app id is in use
	@post '/api/unique-app', (req, res) ->
		_nano (nano) ->
			nano.db.list (err, body) ->
				result = true
				result = false for db in body when db is req.body.value
				res.json result
	# setup in DB with all the correct permissions
	@post '/api/setup', (req, res) ->
		# These events should execute fairly well in order, we use the namespacing for better debugging
		apiSetup =
			req: req
			res: res
			checkUniqueAppId: (next) -> 
				@admin_nano.db.list (err, body) =>
					dbexists = false
					if db is @req.body.appid then dbexists = true for db in body
					if dbexists then @res.json
						success: false
						message: "A unique application name is required"
					else next()
			createDB: (next) ->
				@admin_nano.db.create @req.body.appid, (err, body, headers) =>	
					if err then @res.json
						success: false
						message: "Error creating new site."
						error: err
					else
						@db = @admin_nano.use @req.body.appid
						next()
			generateCouchPass: (next) ->
				@couchpass = ''
				require('crypto').randomBytes 48, (ex, buf) =>
					@couchpass = buf.toString 'hex'
					next()
			createDBAdmin: (next) ->
				@admin_nano.use('_users').insert
					name: @req.user.id
					password: @couchpass
					roles: ['writer']
					type: 'user'
				, "org.couchdb.user:#{@req.user.id}", (err, body) =>
					if err then @res.json
						success: false
						message: "Error creating new user."
						error: err
					else next()
			secureDB: (next) ->
				@db.insert
					validate_doc_update: (new_doc, old_doc, userCtx) -> if userCtx.roles.indexOf('writer') is -1 then throw
						forbidden: "Please Login First"
				, '_design/writerAuthenticatedOnly', (err, body) =>
					if err then @res.json
						success: false
						message: "Error creating permissions file"
						error: err
					else next()
			setupDB: (next) ->
				# login with new user and create docs under him/her
				nano @req.user.id, @couchpass, (user_nano) =>
					@db = user_nano.use @req.body.appid
					async.parallel [@insertSettings, @insertGeneral, @playerViews, @pushAuth0Meta], next
			insertSettings: (cb) =>
				@db.insert
					appId: @req.body.appid
					appName: @req.body.appname
					aggregateFormula: """
						a = (loldb + lolskill) * (ranktier + 1) / lolskillbalance
						w = win + 5
						l = loss + 5
						wl = w / max(w + l, 1)
						0.5*a + ifElse(win + loss == 0, 0.5, wl)*a
					"""
					defaultServer: @req.body.server
				, 'settings', cb
			insertGeneral: (cb) =>
				@db.insert
					preferenceIdNames: roles.names
					players: []
					sessions: []
				, 'general', cb
			playerViews: (cb) =>
				@db.insert
					views:
						by_name:
							map: (doc) -> emit [doc.name], doc._id
						by_in_game_name:
							map: (doc) -> emit [doc.inGameName], doc._id
				, '_design/players', cb
			pushAuth0Meta: (cb) =>
				auth0.updateUserMetadata @req.user.id,
					appid: @req.body.appid
					dbpass: @couchpass
				, cb
			cleanupStep: (err, results) ->
				if err
					@admin_nano.destroy @req.body.appid
					auth0.updateUserMetadata @req.user.id, {}
					@res.json
						success: false
						error: err
				else @res.json
					success: true
		
		_nano (admin_nano) ->
			apiSetup.admin_nano = admin_nano
			apiSetup.checkUniqueAppId apiSetup.createDB apiSetup.generateCouchPass apiSetup.createDBAdmin api.secureDB api.setupDB api.cleanupStep
												
	
	# query DB and see if player name exists already
	@post '/api/unique-player', (req, res) ->
		_nano (nano) ->
			nano.db.view "players", "by_name",
				key: req.body.value
			, (err, view) -> res.json view.rews.length is 0
	# query LOL and see if this player inGameName exists
	@post '/api/player-exists', (req, res) -> lolapi(req.body.server).Summoner.getByName req.body.value, (err, summoner) -> res.json not err
	# add the player to the db
	@post '/api/new-player', (req, res) ->
		_nano (nano) ->
			nano.db.list (err, body) ->
				result = true
				result = false for db in body when db is req.body.value
				res.json result
	
	
	@post '/api/get-attendance', (req, res) ->
		attendance.getAttendance "#{req.body.eventid}", req.body.username, req.body.password, (err, attending) ->
			if err then res.json 400, attending
			else res.json 200, attending
	
	@post '/api/test-formula', (req, res) ->
		tempaggregateFormula = formula.aggregateFormula
		formula.aggregateFormula = req.body.formula
		players = req.body.players
		for key, player of players
			formula.calculateAggregate player
		res.json 200, players
	
	@post '/api/save-formula', (req, res) =>
		req.session.data.aggregateFormula = formula.aggregateFormula = req.body.formula
		# return the test data, same as test-formula
		players = req.body.players
		for key, player of players
			formula.calculateAggregate player
		res.json 200, players
		# need to recalc all the formulas at this point
		#for key, player in @session.players
		for key, player of req.session.data.players when player.scores isnt undefined
			formula.calculateAggregate player
			#@io.sockets.in(@session.data.clan_name).emit 'playerupdate',
			@publicio.in(req.session.data.appId).emit 'playerupdate',
				player: player
				localonly: false
	
	@get '/api/load-data/:appId', (req, res) ->
		_nano (admin_nano) ->
			admin_nano.db.list (err, body) ->
				result = true
				result = false for db in body when db is req.body.id
				if not result then res.json 404, {error: "No app with name"}
				else
					db = admin_nano.use req.params.appId
					req.session.data = {}
					db.get 'general', (err, body) ->
						if not err then res.json 200, req.session.data = body
						else res.json 500, err
	
	@get '/api/load-settings', @auth, (req, res) => @user_db req, (db) -> db.get 'settings', (err, body) -> res.json 200, body

@publicio = ->
		
@privateio = (ctx) ->
	# @ is the socket instance
	@on 'updateplayers', (data) =>
		# console.log "Update Players"
		scraper.updatePlayers data.players, (event, playerid, data={}) =>
			data.pid = playerid
			@context.publicio.in(@client.room).emit event, data
		, (err, player) =>
			# console.log "Broadcast update done for #{player.name}  in #{@client.room}"
			if player.pid? and not req.session.data.players[player.pid]?
				req.session.data.players[player.pid] = player
			@context.publicio.in(@client.room).emit 'playerupdate',
				player: player
				localonly: data.localonly

# normally set during login
#@session.data = 
static_data = 
	appId: 'taw_ll5'
	appName: 'TAW LL5'
	aggregateFormula: """
		a = (loldb + opgg) * (ranktier + 1)
		w = win + 5
		l = loss + 5
		wl = w / max(w + l, 1)
		0.5*a + ifElse(win + loss == 0, 0.5, wl)*a
	"""
	preferenceIdNames: roles.names
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
				aggregate: 43389
			rank:
				label: 'Silver V'
				ranktier: 6
				image: "silver_#{6 - 6 % 5}.png"
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
			scores: { loldb: 6828, opgg: 1629, win: 2, loss: 8, aggregate: 71039 }
			rank: { label: 'Gold V', ranktier: 11, image: "gold_#{6 - 11 % 5}.png" }
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
			scores: { loldb: 1766, opgg: 0, win: 2, loss: 0, aggregate: 2649 }
			name: 'Jesilicious'
			rank: { label: 'Unranked', ranktier: 0, image: 'unranked.png' }
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
			name: 'Tuesday Practice'
			teams: 
				t0:
					name: 'The Musketeers'
					players: ['p0']
					win: 3
					loss: 2
				t1:
					name: 'Alditha Alma'
					leader: 'p1'
					players: ['p1','p2']
					win: 2
					loss: 3
			playerTeamMatrix:
				p0:
					t0:
						against:
							win: 3
							loss: 3
						with:
							win: 1
							loss: 0
					t1:
						against:
							win: 1
							loss: 2
						with:
							win: 2
							loss: 0
				p1:
					t1:
						against:
							win: 0
							loss: 3
						with:
							win: 3
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