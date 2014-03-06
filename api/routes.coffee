loldb = require './loldb_score_scraper'
balancer = require './balance_algorithm'
async = require 'async'
roles = require './roles'

@include = ->
	
	#this takes one list of players (or URL's), parses them to get their scores and then balances out the teams. Returns json as follows: {confidance: -ve % is favoured to team 0, teams: [[players in team with role],[players in team with role]]}
	@post '/balance-teams': (req, res) ->
		console.log '==== start balance-teams ===='
		console.log 'updating players'
		#we assume a player at this point has a preference array, a loldb url or manual score and a name
		loldb.updatePlayers req.body.players, (err, players) ->
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
		async.parallel [ (callback) -> loldb.updatePlayers req.body.teams[0], callback
			, (callback) -> loldb.updatePlayers req.body.teams[1], callback
		], (err, teams) ->
			res.json 200, balancer.rateTeamBalanceConfidance teams
	
	@post '/balance-multi-teams': (req, res) ->
		loldb.getPlayers req.body.players, (err, players) ->
			loldb.getPlayers req.body.captains, (err, captains) ->
				result = balancer.multiteambalance players, captains
				res.json 200, result