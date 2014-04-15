scraper = require './api/score_scraper'
players = [
	inGameName: 'Xan'
	server: 'oce'
,
	inGameName: 'TAW Nocturnal'
	server: 'oce'
,
	inGameName: 'Jesilicious'
	server: 'oce'
,
	inGameName: 'Shawn'
	server: 'oce'
,
	inGameName: 'Crusnix'
	server: 'oce'
,
	inGameName: 'ONISWORDX'
	server: 'oce'
]
scraper.getPlayers players, (err, players) ->
	scraper.updatePlayers players, (message, pid) ->
		return
	, (err, player) ->
		console.log err
		console.log player

###
scraper = require './api/attendance_scraper'

scraper.getAttendance '21556', 'xanetia', "fy616*Q85&*J", (err, attending) -> console.log attending
###
###
tests = 
	noc: [ 1521, 781, 613, 626, 526, 480, 444, 259 ],
	xan: [
		1109,
		912,
		861,
		652,
		523,
		449,
		443,
		477,
		390,
		447,
		440,
		338,
		392,
		252,
		231,
		409,
		281,
		210,
		180
	]
	shawn: [
		1226,
		685,
		568,
		558,
		542,
		539,
		497,
		482,
		453,
		423,
		403,
		260,
		259,
		259,
		210
	]

for name, values of tests
	 the higher the balanced number is the less balanced his/her champion pool is
	nextdiff = values.map (value, index) -> if index isnt values.length - 1 then value - values[index + 1] else 0
	totaldiff = nextdiff.reduce (a,b) -> a+b
	average = totaldiff / (nextdiff.length - 1)
	balanced = Math.abs nextdiff.map (value) -> if value > average then 1 else if value is average then 0 else -1
		.reduce (a,b) -> a+b
###
###
	top = values[0]
	rev = values.reverse()
	rev.splice values.length-1, 1
	topsum = 0
	# y = a + bx
	a = rev[0]
	grads = []
	i = 1
	while i < rev.length
		grads.push (rev[i] - a) / i
		i++
	tot = grads.reduce (a,b) -> a+b
	avgrad = tot / grads.length
	target = a + avgrad*(grads.length + 1)
	console.log "Target is #{target}, actual is #{top}, error is #{target / top}"
###
	
	
	
###
	sum = values.reduce (a,b) -> a + b
	gradient = (values[values.length - 1] - values[0]) / (values.length-1)
	console.log "Sum #{sum}"
	console.log "Gradient #{gradient}"
	deviation = values.map (value, index) -> Math.round index * gradient + values[0]
	diffDeviation = values.map (value, index) -> if index is 0 then 0 else value / (values[index-1] + value)
	console.log diffDeviation
	differror = diffDeviation.reduce (a,b) -> a+b
	console.log 1 - (differror / (diffDeviation.length - 1))
	error = deviation.map (value, index) -> value - values[index]
		.reduce (a,b) -> a + b
	console.log "Error #{error}"
	console.log "Average Error: #{error / values.length}"
	console.log "Deviation sum: #{(error / values.length) / sum}"
	
###