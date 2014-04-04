request = require 'request'
tough = require 'tough-cookie'
cookieJar = request.jar()
cookieJar.setCookie '__utma=124484948.1915756135.1393795391.1393795391.1393795391.1', 'http://oce.op.gg/', {}, ->
cookieJar.setCookie '__utmc=124484948', 'http://oce.op.gg/', {}, ->
cookieJar.setCookie '__utmz=124484948.1393795391.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)', 'http://oce.op.gg/', {}, ->
cookieJar.setCookie 'ne92_unique_user=1', 'http://oce.op.gg/', {}, ->
cookieJar.setCookie 'customLocale=en_US', 'http://oce.op.gg/', {}, ->
cookieJar.setCookie 'setTiming=%7B%22locale%22%3A1395374753%7D', 'http://oce.op.gg/', {}, ->
cookieJar.setCookie '_ga=GA1.3.1915756135.1393795391', 'http://oce.op.gg/', {}, ->
request.defaults
	jar: cookieJar

cheerio = require 'cheerio'
async = require 'async'
roles = require './roles'
calculator = require './formula'

exports = module.exports =
	servers:
		oce:
			loldb: '9'
			opgg: 'oce'
	currentSeason: 4
	
	#creates an alial for getProfile
	updatePlayer: @getprofile
	# takes in an array of objects, each object must have at least a loldb url
	# cb is called when each player is updated
	updatePlayers: (players, cb) ->
		callfunctions = []
		for p in players
			callfunctions.push ((player) => ((callback) =>
				# for passback updating
				player.updating = false
				delete player.updatingerror
				try
					if not player.urls? or not player.urls.opgg? or not player.urls.opgg.root? or not player.urls.opgg.id? or not player.urls.loldb?
						@getbyname player, (err, player) => @getprofile player, cb
					else @getprofile player, cb
				catch any
					player.updatingerror = "Unknown exception occurred"
					cb false, player
			)) p
		async.parallel callfunctions #callback here should update the DB
	
	getprofile: (player, finalCb) ->
		# after updates have finished set the lastupdate time and update the session stored player
		cb = ->
			player.lastupdate = Date.now()
			# find player by player.pid in session and update
			finalCb.apply this, arguments
		if not player.scores? then player.scores = {win: 0, loss: 0}
		opgg = (player, cb) =>
			try
				@getOpggProfile player, =>
					if not player.updatingerror? or player.updatingerror is '' then calculator.calculateAggregate player
					cb false, player
			catch error
				player.updatingerror = "Error Occured Updating OPGG profile"
				cb false, player
			
		try
			@getLoldbProfile player, =>
				opgg player, cb
		catch error
			player.updatingerror = "Error Occured Updating LOLDB profile"
			opgg player, cb
	
	getLoldbProfile: (player, cb) ->
		request
			uri: player.urls.loldb
			jar: cookieJar
		, (err,resp,body) -> if err then throw err else
			try
				$ = cheerio.load body
				# this catches any player changing his/her name due to loldb assigning a unique URL - therefore the opgg won't fail
				player.inGameName = $('div.sumBse div.fl.sumName p:first-child').html()
				if not player.name? then player.name = player.inGameName
				player.scores.loldb = parseInt $('div.fr.fightRank dl:first-child dd').html().trim().replace /[^0-9]*/g, ''
				rankString = $('div.portlet div.ranked div.fl.mBoxCon.boxsdow:last-child div.rankedInfo p').html().trim()
				rankData = rankString.split ' '
				rankTier = 0
				if rankData.length is 2
					switch rankData[0].toLowerCase()[0] #first character
						when 'b' then rankTier += 0
						when 's' then rankTier += 5
						when 'g' then rankTier += 10
						when 'p' then rankTier += 15
						when 'd' then rankTier += 20
						when 'c' then rankTier += 25
					switch rankData[1].toLowerCase()
						when 'v' then rankTier += 1
						when 'iv' then rankTier += 2
						when 'iii' then rankTier += 3
						when 'ii' then rankTier += 4
						when 'i' then rankTier += 5
				player.rank =
					label: if rankString is 'NONE' then 'Unranked' else rankString
					ranktier: rankTier
					image: if rankString is 'NONE' then 'unranked' else "#{rankData[0].toLowerCase()}_#{rankTier % 5}.png"
				if not player.preference? or player.preference.length isnt 5
					prefs = JSON.parse $('div.mBoxList.clearfix div.module div.fr.mBox.personProper div.mBoxConList.clearfix script').text().trim().match(/// data:([^\]]*\]) ///)[1]
					prefs.sort (a,b) -> b.value - a.value
					player.preference = []
					for i of prefs
						player.preference[i] = roles.getIndex prefs[i].label
				cb false, player
			catch error
				player.updatingerror = "Error Occured Updating LOLDB profile"
				cb false, player
	
	getOpggProfile: (player, cb) ->
		request.post(
			uri: player.urls.opgg.root + "ajax/mmr.json/"
			jar: cookieJar
		, (err,resp,body) => if err then throw err else
			try
				json = JSON.parse body
				player.scores.opgg = if json.error then 0 else parseInt json.mmr.replace /[^0-9]*/g, ''
			catch any
				player.updatingerror = "Error Getting OPGG MMR"
			request
				uri: player.urls.opgg.root + "champions/userName=#{player.inGameName}"
				jar: cookieJar
			, (err,resp,body) => if err then throw err else
				# "get top champions #{player.inGameName} @ #{player.urls.opgg.root}champions/userName=#{player.inGameName}"
				$ = cheerio.load body
				# convert from seconds to ms
				lastUpdate = 1000 * parseInt $('span.lastUpdate span._timeago').attr 'data-datetime'
				# if last time updated 24 hours ago
				# "Remote Update from OPGG #{lastUpdate} #{Date.now()} #{lastUpdate < Date.now() - 86400000}"
				if lastUpdate < Date.now() - 86400000 then @remoteUpdateOpgg player
				championRows = $ "div.ChampionStats div.ChampionsStatsSeason-active table tbody tr"
				player.mostPlayedChampions = ({
					champion: championRows.eq(i).find('div.championName').text().trim()
					games: championRows.eq(i).find('.total').text().trim()
					kda: championRows.eq(i).find('.kdaratio').text().trim()
				}for i in [0...Math.min 3, championRows.length])
				cb false, player
		).form
			userName: player.inGameName
	
	# should be called max once per player per day
	remoteUpdateOpgg: (player) ->
		request.post(
			uri: player.urls.opgg.root + "ajax/update.json/"
			jar: cookieJar
		).form
			summonerId: player.urls.opgg.id
	
	#takes in an array of player objects, requires inGameName and server attributes
	getPlayers: (players, cb) ->
		callfunctions = []
		for p in players
			if p.inGameName? and p.inGameName isnt '' and p.server and p.server isnt '' then callfunctions.push ((player) => ((callback) => @getbyname player, callback)) p
		async.parallel callfunctions, cb
	
	getbyname: (player, cb) ->
		if not player.urls then player.urls = {}
		player.urls.opgg =
			root: "http://#{@servers[player.server].opgg}.op.gg/summoner/"
		try
			request
				uri: "http://loldb.gameguyz.com/analyze/search?search_text=#{player.inGameName}&c_server=#{@servers[player.server].loldb}"
				jar: cookieJar
			, (err,resp,body) => if err then throw err else
				$ = cheerio.load body
				playerURL = $('div.search_result_content div.result_list').attr('onclick')
				if not playerURL?
					player.updatingerror = "LOLDB Server Is down for region, please try again later"
					return cb false, player
				playerURL = playerURL.substring 17
				playerURL = playerURL.substring 0, playerURL.length - 2
				player.urls.loldb = "http://loldb.gameguyz.com#{playerURL}"
				try
					request
						uri: "#{player.urls.opgg.root}userName=#{player.inGameName}"
						jar: cookieJar
					, (err,resp,body) => if err then throw err else
						$ = cheerio.load body
						player.urls.opgg.id = $('[data-summoner-id]').attr 'data-summoner-id'
						cb false, player
				catch error
					player.updatingerror = "Error getting OPGG"
					cb false, player
		catch error
			player.updatingerror = "Error Getting loldb"
			cb false, player