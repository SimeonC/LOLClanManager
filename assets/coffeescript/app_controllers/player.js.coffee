PlayerController = class PlayerController
	constructor: ($scope, $routeParams, data, sharedFuncs, sockets) ->
		angular.extend $scope, sharedFuncs($scope)
		socket = sockets
			playerUpdate: (player) ->
				angular.extendDeep $scope.data.players[$routeParams.playerId], player.player
				if not $scope.player.leader then $scope.player.leader = false
		$scope.reloadFromServers = ->
			$scope.player.updating = true
			delete $scope.player.updatingerror
			socket.emit 'update-players',
				players: [$scope.player]
				localonly: false
		
		$scope.data = data
		$scope.player = $scope.data.players[$routeParams.playerId]
		if not $scope.player.leader then $scope.player.leader = false
		$scope.winPercent = -> if $scope.player.scores? then $scope.player.scores.win / Math.max 1, $scope.player.scores.win + $scope.player.scores.loss else 0