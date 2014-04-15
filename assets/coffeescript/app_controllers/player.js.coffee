PlayerController = class PlayerController
	constructor: ($scope, $routeParams, data, sharedFuncs, sockets) ->
		angular.extend $scope, sharedFuncs($scope)
		socket = sockets
			playerUpdate: (player) ->
				angular.extendDeep $scope.data.players[$routeParams.playerId], player.player
				if not $scope.player.leader then $scope.player.leader = false
		$scope.reloadFromServers = ->
			socket.privatesocket.emit 'updateplayers',
				players: [$scope.player]
				localonly: false
		
		$scope.data = data
		$scope.player = $scope.data.players[$routeParams.playerId]
		if not $scope.player.leader then $scope.player.leader = false
		$scope.winPercent = -> if $scope.player.scores? then $scope.player.scores.win / Math.max 1, $scope.player.scores.win + $scope.player.scores.loss else 0
		
		$scope.sessionstats = 
			wins:
				with:
					count: 0
					team: ''
				against:
					count: 0
					team: ''
			losses:
				with:
					count: 0
					team: ''
				against:
					count: 0
					team: ''
		angular.forEach $scope.data.sessions, (session) ->
			teamMatrix = session.playerTeamMatrix[$routeParams.playerId]
			for key, team of teamMatrix
				if team.with.win > $scope.sessionstats.wins.with.count
					$scope.sessionstats.wins.with.count = team.with.win
					$scope.sessionstats.wins.with.team = session.teams[key].name
				if team.with.loss > $scope.sessionstats.losses.with.count
					$scope.sessionstats.losses.with.count = team.with.loss
					$scope.sessionstats.losses.with.team = session.teams[key].name
				if team.against.win > $scope.sessionstats.wins.against.count
					$scope.sessionstats.wins.against.count = team.against.win
					$scope.sessionstats.wins.against.team = session.teams[key].name
				if team.against.loss > $scope.sessionstats.losses.with.count
					$scope.sessionstats.losses.against.count = team.against.loss
					$scope.sessionstats.losses.against.team = session.teams[key].name