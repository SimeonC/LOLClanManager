NewPlayerController = class NewPlayerController
	constructor: ($location, data, settings, $http) ->
		$scope.servers = 
			oce: "Oceania"
			na: "North America"
		$scope.server-dropdown = (player) ->
			result = []
			for name, key in $scope.servers
				result.push
					text: name
					click: => player.server = key
		$scope.errorMsg = 
			name:
				failure: "A player with this name already exists"
				pending: "We are checking to see if a player with this name already exists..."
			ingamename:
				failure: "We cannot find a summoner in League of Legends with this name"
				pending: "We are checking to see if this summoner exists in League of Legends..."
		
		$scope.player =
			name: ''
			inGameName: ''
			server: settings.defaultServer
		
		$scope.updateInGame = (player) -> player.inGameName = player.name
		
		$http.post('/api/new-player', $scope.player).success (_data) ->
			# temp data, full data will be pushed from the server when found
			data.players[_data.id] = 
				name: $scope.player.name
				inGameName: $scope.player.inGameName
				server: $scope.player.server
				win: 0
				loss: 0
			$location.path("manage/player/#{_data.id}").replace()