request = require 'request'
cheerio = require 'cheerio'
async = require 'async'
roles = require './roles'

exports = module.exports =
	#takes in an array of loldb.gameguyz.com summoner profile URL's and calls the cb function with the parameter of scores in the same order as the URL's
	getscores: (urls, cb) ->
		callfunctions = []
		for u of urls
			callfunctions[u] = ((url) => ((callback) => @getscore url, callback)) urls[u]
		async.parallel callfunctions, cb
	
	getscore: (url, cb) ->
		request url, (err,resp,body) -> if err then throw err else cb false, cheerio.load(body)('div.fr.fightRank dl:first-child dd').html().replace /[^0-9]*/g, ''
	
	#takes in an array of objects, each object must have at least a loldb url
	updatePlayers: (players, cb) ->
		callfunctions = []
		for p in players
			callfunctions.push ((player) => ((callback) => @getprofile player, callback)) p
		async.parallel callfunctions, cb
	
	getprofile: (player, cb) ->
		request player.url, (err,resp,body) ->
			if err
				throw err
			else
				$ = cheerio.load body
				if not player.name? then player.name = $('div.sumBse div.fl.sumName p:first-child').html()
				player.score = $('div.fr.fightRank dl:first-child dd').html().replace /[^0-9]*/g, ''
				if not player.preference? or player.preference.length isnt 5
					prefs = JSON.parse $('div.mBoxList.clearfix div.module div.fr.mBox.personProper div.mBoxConList.clearfix script').text().match(/// data:([^\]]*\]) ///)[1]
					prefs.sort (a,b) -> b.value - a.value
					player.preference = []
					for i of prefs
						player.preference[i] = roles.getIndex prefs[i].label
				cb false, player
	
	#takes in an array of names
	getPlayers: (players, cb) ->
		callfunctions = []
		for p in players
			if p? and p isnt '' then callfunctions.push ((player) => ((callback) => @getbyname player, callback)) p
		async.parallel callfunctions, cb
	
	getbyname: (name, cb) ->
		request "http://loldb.gameguyz.com/analyze/search?search_text=#{name}&c_server=9", (err,resp,body) => if err then throw err else
			try
				$ = cheerio.load body
				playerURL = $('div.search_result_content div.result_list').attr('onclick').substring 17
				playerURL = playerURL.substring 0, playerURL.length - 2
				@getprofile
					url: "http://loldb.gameguyz.com#{playerURL}"
					name: name
				, cb
			catch error
				console.log error
				

#exports.updatePlayers [{url:'http://loldb.gameguyz.com/analyze/default/index/200090807/9/345086'},{url:'http://loldb.gameguyz.com/analyze/default/index/200082221/9/330730'},{url:'http://loldb.gameguyz.com/analyze/default/index/200086594/9/343045'}], (err, results) -> console.log results
#me: http://loldb.gameguyz.com/analyze/default/index/200090807/9/345086
#phil: http://loldb.gameguyz.com/analyze/default/index/200082221/9/330730
#shawn: http://loldb.gameguyz.com/analyze/default/index/200086594/9/343045
