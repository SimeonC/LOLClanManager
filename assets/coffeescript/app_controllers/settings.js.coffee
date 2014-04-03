SettingsController = class SettingsController
	constructor: ($scope, $routeParams, data, sharedFuncs, $http, sockets) ->
		angular.extend $scope, sharedFuncs($scope)
		socket = sockets
			playerUpdate: (player) ->
				if player.updatingerror? and player.updatingerror isnt ''
					$scope.players[player.pid] = player
		
		$scope.data = data
		$scope.formula = """
			a = (loldb + opgg) * (ranktier + 1)
			wl = (win / (win + loss))
			0.5*a + a*wl
		"""
		$scope.allPlayers = []
		$scope.players = {}
		# add 10 players for demo purposes
		count = 0
		for key, player of $scope.data.players when not player.updatingerror? and not player.updating and count < 10
			$scope.allPlayers.push key
			$scope.players[key] = angular.extend {}, $scope.data.players[key]
			$scope.players[key].scores = angular.extend {}, $scope.data.players[key].scores
			count++
		
		$scope.reCalcPlayers = ->
			$http.post('/api/test-formula',
				formula: $scope.formula
				players: $scope.players
			).success (players) ->
				$scope.players = players
				if $scope.debugPid isnt '' then $scope.debugPlayer $scope.debugPid
		
		$scope.selectedDebug = [
			line: $scope.formula
			result: '---'
		]
		
		$scope.debugPid = $scope.allPlayers[0]
		$scope.debugPlayer = (pid) ->
			$scope.selectedDebug = []
			$scope.debugPid = pid
			formulaLines = $scope.formula.split '\n'
			playerScores = $scope.players[pid].scores
			if formulaLines.length <= 1
				$scope.selectedDebug = [
					line: $scope.formula
					result: playerScores.aggregate
				]
			else for i in [0...formulaLines.length]
				$scope.selectedDebug.push
					line: formulaLines[i]
					result: playerScores.debug[i]
		
		$scope.reCalcPlayers()