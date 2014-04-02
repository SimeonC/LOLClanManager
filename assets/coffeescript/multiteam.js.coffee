#angular logic to go here

module = angular.module 'lolbalancer', []

class balancer
	constructor: ($scope, $http) ->
		$scope.players = []
		$scope.captains = []
		$scope.addPlayer = -> $scope.players.push ''
		$scope.addCaptain = -> $scope.captains.push ''
		$scope.result =
			confidence: 0
			teams: []
		$scope.sendingRequest = false
		$scope.crunchNumbers = ->
			$scope.sendingRequest = true
			$http.post('/balance-multi-teams',
				players: $scope.players
				captains: $scope.captains
			).success (data) ->
				$scope.result = data
				$scope.sendingRequest = false
		$scope.confidenceDisplay = (confidence) ->
			if confidence > 0 then "Team favoured to win by #{parseInt Math.abs confidence * 100}% > "
			else if confidence < 0 then " < Team favoured to win by #{parseInt Math.abs confidence * 100}%"
			else if confidence is '?' then 'Non-In house game'
			else 'Calculate Results first'
@balancer = balancer