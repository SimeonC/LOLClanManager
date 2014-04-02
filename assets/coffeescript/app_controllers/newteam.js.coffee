NewTeamController = class NewTeamController
	constructor: ($location, data) ->
		###
			# make request to get new id
			data.players[id] =
				name: ''
				win: 0
				loss: 0
			$location.path "/session/#{id}"
		###
		$location.path('team/s1/t1').replace()