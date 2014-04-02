DashboardController = class DashboardController
	constructor: ($scope, data, sharedFuncs) ->
		angular.extend $scope, sharedFuncs($scope)
		$scope.data = data
		$scope.playerOrder = Object.keys data.players
		$scope.leaderThenPlayerName = (key) -> $scope.leaderFirst(undefined)(key) + $scope.playerNameByRef(key)