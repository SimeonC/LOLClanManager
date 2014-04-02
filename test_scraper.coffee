# scraper = require './api/score_scraper'
# players = [
# 	inGameName: 'Xan'
# 	server: 'oce'
# ,
# 	inGameName: 'NocturnalGannet'
# 	server: 'oce'
# ,
# 	inGameName: 'Jesilicious'
# 	server: 'oce'
# ,
# 	inGameName: 'Shawn'
# 	server: 'oce'
# ]
# scraper.getPlayers players, (err, players) -> scraper.updatePlayers players, (err, player) ->
# 	console.log err
# 	console.log player

scraper = require './api/attendance_scraper'

scraper.getAttendance '21556', 'xanetia', "fy616*Q85&*J", (err, attending) -> console.log attending