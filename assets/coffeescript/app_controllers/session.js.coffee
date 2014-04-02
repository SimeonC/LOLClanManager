SessionController = class SessionController
	constructor: ($scope, $routeParams, data, $location, sharedFuncs) ->
		angular.extend $scope, sharedFuncs($scope)
		$scope.data = data
		$scope.sessionKey = $routeParams.sessionId
		$scope.session = $scope.data.sessions[$routeParams.sessionId]
		$scope.teamScore = (team) -> team.players.reduce ((a, b) -> a + ($scope.data.players[b].scores.loldb + $scope.data.players[b].scores.opgg)), 0