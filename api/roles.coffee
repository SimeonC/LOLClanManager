#this file is the setup of the ID's for the roles. If we implement a DB this should be moved to there

exports = module.exports =
	names: [ 'AD Carry', 'Support', 'Middle Lane', 'Top Lane', 'Jungler' ]
	getIndex: (name) ->
		for i of @names
			if @names[i] is name then return parseInt i
		return false #name not found