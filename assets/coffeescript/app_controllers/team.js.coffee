TeamController = class TeamController
	constructor: ($scope, $routeParams, data, sharedFuncs) ->
		angular.extend $scope, sharedFuncs $scope
		$scope.data = data
		$scope.session = $scope.data.sessions[$routeParams.sessionId]
		$scope.team = $scope.data.sessions[$routeParams.sessionId].teams[$routeParams.teamId]
		$scope.teamId = $routeParams.teamId
		
		# copy to a temp array for cancel functions
		$scope.attachedPlayers = (pid for pid in $scope.team.players)
		$scope.statsOrder = (pid for pid, value of $scope.data.players)
		$scope.playersOnOtherTeams = []
		angular.forEach $scope.session.teams, (value, key) -> if key isnt $scope.teamId then $scope.playersOnOtherTeams = $scope.playersOnOtherTeams.concat value.players
		$scope.availablePlayersList = []
		angular.forEach $scope.data.players, (value, key) -> if -1 is $scope.attachedPlayers.indexOf key then $scope.availablePlayersList.push key
		
		$scope.onOtherTeam = (pid) -> $scope.playersOnOtherTeams.indexOf(pid) isnt -1
		
		$scope.attachPlayer = (pid) ->
			$scope.attachedPlayers.push pid
			$scope.availablePlayersList.splice $scope.availablePlayersList.indexOf(pid), 1
		
		$scope.unattachPlayer = (pid) ->
			$scope.attachedPlayers.splice $scope.attachedPlayers.indexOf(pid), 1
			$scope.availablePlayersList.push pid
		
		$scope.sortOrder = 1
		$scope.getSortOrder = (pid) ->
			( # if on other team push to bottom of list
				if $scope.playersOnOtherTeams.indexOf(pid) isnt -1
					if $scope.sortOrder is 1 then -100000000
					else 'a'
				else 0
			) +
			( # rig so leaders allways show at the top!
				if $scope.sortOrder is 1 then (2-$scope.leaderFirst($scope.team)(pid)) * 1000000 + $scope.playerScoreByRef pid
				else $scope.leaderFirst($scope.team)(pid) + $scope.playerNameByRef pid
			)
		
		$scope.getSortOrder2 = (pid) -> $scope.leaderFirst($scope.team)(pid) + $scope.playerNameByRef pid