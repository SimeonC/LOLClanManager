NewPlayerController = class NewPlayerController
	constructor: ($location, data) ->
		###
			# make request to get new id
			data.players[id] =
				name: ''
				win: 0
				loss: 0
			$location.path('manage/player/p1').replace()
		###
		$location.path('manage/player/p1').replace()