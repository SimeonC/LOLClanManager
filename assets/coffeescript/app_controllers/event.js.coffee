EventController = class EventController
	constructor: ($scope, $routeParams, data, $location, sharedFuncs) ->
		angular.extend $scope, sharedFuncs($scope)
		$scope.data = data
		$scope.session = $scope.data.sessions[$routeParams.sessionId]
		$scope.event = $scope.session.history[$routeParams.eventId]
		$scope.preferenceRolesString = (preferenceList) ->
			names = ['AD Carry','Support','Middle Lane','Top Lane','Jungler']
			roles = (names[preferenceList[i]] for i in [0..2])
			"#{roles[0]}, #{roles[1]}, #{roles[2]}"
		$scope.setWinner = (pair, winteam) ->
			# win flag is either 'win' or 'loss'
			increment = (value, increment) ->
				value = Math.min value + increment, 0
			playerTeamMod = (teamWin, teamLoss, increment) ->
				incrementVal = 1
				if not increment then incrementVal = -1
				if teamWin? then angular.forEach teamWin.players, (pid) ->
					increment $scope.data.players[pid].scores.win, incrementVal
					if not $scope.session.playerTeamMatrix[pid]? then $scope.session.playerTeamMatrix[pid] = {}
					if not $scope.session.playerTeamMatrix[pid][teamWin.id]? then $scope.session.playerTeamMatrix[pid][teamWin.id] =
						against:
							win: 0
							loss: 0
						with:
							win: 0
							loss: 0
					increment $scope.session.playerTeamMatrix[pid][teamWin.id].with.win, incrementVal
					if teamLoss?
						if not $scope.session.playerTeamMatrix[pid][teamLoss.id]? then $scope.session.playerTeamMatrix[pid][teamLoss.id] =
							against:
								win: 0
								loss: 0
							with:
								win: 0
								loss: 0
						increment $scope.session.playerTeamMatrix[pid][teamLoss.id].against.win, incrementVal
				if teamLoss? then angular.forEach teamLoss.players, (pid) ->
					increment $scope.data.players[pid].scores.loss, incrementVal
					if not $scope.session.playerTeamMatrix[pid]? then $scope.session.playerTeamMatrix[pid] = {}
					if not $scope.session.playerTeamMatrix[pid][teamLoss.id]? then $scope.session.playerTeamMatrix[pid][teamLoss.id] =
						against:
							win: 0
							loss: 0
						with:
							win: 0
							loss: 0
					increment $scope.session.playerTeamMatrix[pid][teamLoss.id].with.loss, incrementVal
					if teamWin?
						if not $scope.session.playerTeamMatrix[pid][teamWin.id]? then $scope.session.playerTeamMatrix[pid][teamWin.id] =
							against:
								win: 0
								loss: 0
							with:
								win: 0
								loss: 0
						increment $scope.session.playerTeamMatrix[pid][teamWin.id].against.loss, incrementVal
					
			# add for change to
			if winteam is 1 then playerTeamMod pair.team1, pair.team2, true
			else if winteam is 2 then playerTeamMod pair.team2, pair.team1, true
			# subtract for change from
			if pair.winner is 1 then playerTeamMod pair.team1, pair.team2, false
			else if pair.winner is 2 then playerTeamMod pair.team2, pair.team1, false
			pair.winner = winteam
			#save!
		$scope.backToSession = -> $location.path("session/#{$routeParams.sessionId}").replace()