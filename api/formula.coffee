math = require('mathjs')()

exports = module.exports =
	# load by user settings!
	aggregateFormula: """
		a = (loldb + opgg) * (ranktier + 1)
		wl = win / max(win + loss, 1)
		0.5*a + ifElse(win + loss == 0, 0.5, wl)*a
	"""
	calculateAggregate: (player) ->
		temp = {}
		temp[key] = value for key, value of player.scores
		temp['ranktier'] = if player.rank? then player.rank.ranktier else 0
		player.scores.aggregate = math.eval @aggregateFormula, temp
		if player.scores.aggregate.length?
			player.scores.debug = player.scores.aggregate
			player.scores.debug[player.scores.debug.length - 1] = math.round player.scores.debug[player.scores.debug.length - 1], 0
			player.scores.aggregate = player.scores.aggregate[player.scores.aggregate.length - 1]
		player.scores.aggregate = math.round player.scores.aggregate, 0