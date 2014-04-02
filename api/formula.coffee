math = require('mathjs')()

exports = module.exports =
	# load by user settings!
	aggregateFormula: 'loldb + opgg'
	calculateAggregate: (scores) ->
		math.eval "aggregate = #{@aggregateFormula}", scores
		# clean up scores
		delete scores.ans