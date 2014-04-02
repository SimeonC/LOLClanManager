PlayerController = class PlayerController
	constructor: ($scope, $routeParams, data, sharedFuncs) ->
		angular.extend $scope, sharedFuncs($scope)
		$scope.data = data
		$scope.player = $scope.data.players[$routeParams.playerId]
		$scope.player.win = 0
		$scope.player.loss = 0
		angular.forEach $scope.data.sessions, (session) ->
			angular.forEach session.playerTeamMatrix[$routeParams.playerId], (team) ->
				$scope.player.win += team.win
				$scope.player.loss += team.loss
		$scope.player.winpercent = if $scope.player.loss is 0 and $scope.player.win is 0 then 0 else if $scope.player.loss is 0 then 100 else $scope.player.win / $scope.player.loss