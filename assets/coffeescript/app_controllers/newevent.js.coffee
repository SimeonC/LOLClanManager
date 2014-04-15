NewEventController = class NewEventController
	constructor: ($scope, $routeParams, $filter, data, $sce, $document, $timeout, $modal, $location, sharedFuncs, $http, sockets) ->
		angular.extend $scope, sharedFuncs($scope)
		socket = sockets
			playerUpdate: (player) ->
				if player.updatingerror? and player.updatingerror isnt ''
					$scope.removePlayer player.pid
				else if -1 is $scope.allPresentPlayers.indexOf(player.pid)
					$scope.allPresentPlayers.push player.pid
				$scope.allPresentPlayers.sort (a,b) -> $scope.playerScoreByRef(b) - $scope.playerScoreByRef a
		keyDownEvent = ($event) ->
			if ($event.ctrlKey or $event.metaKey)
				index = $scope.indexForKeycode($event.which)
				if index < 0 or not $scope.tempTeams[$scope.tempTeamsOrder[index]]? then return
				$event.preventDefault()
				$scope.$apply -> $scope.assignTeam $scope.tempTeamsOrder[index], false
		# we do NOT want this to fire multiple time EVER
		$document.off('keydown', keyDownEvent).on 'keydown', keyDownEvent
		movePlayerById = (from, to, pid) ->
			if from.length and from.indexOf(pid) >= 0 and from.indexOf(pid) < from.length
				to.push from.splice(from.indexOf(pid), 1)[0]
		updateQueueTimeout = undefined
		updateQueue = []
		sendUpdateQueue = ->
			tempUpdateQueue = updateQueue
			updateQueue = []
			socket.privatesocket.emit 'updateplayers',
				players: tempUpdateQueue
			# responses done by sockets
		updatePlayerById = (pid) ->
			player = $scope.data.players[pid]
			if not player.lastupdate? or player.lastupdate < Date.now() - 86400000
				# if updated more than 24 hours ago - re-update
				if updateQueueTimeout? then $timeout.cancel updateQueueTimeout
				player.updating = true
				# delay for a second to see if we aren't adding any more
				updateQueue.push player
				updateQueueTimeout = $timeout ->
					sendUpdateQueue()
				, 2000
		$scope.multiFixPlayer = false
		$scope.fixPlayer = (pid) ->
			player = $scope.data.players[pid]
			player.pid = pid
			$scope.newPlayers.players.push player
			if not $scope.multiFixPlayer then $scope.newPlayers.show()
		
		$scope.newPlayers =
			players: []
			modal: $modal
				scope: $scope
				template: 'newevent/newplayers.tpl.html'
				show: false
				eventPrefix: 'newEventModal'
				backdrop: 'static'
				keyboard: false
			show: -> @modal.show()
			process: ->
				for player in @players
					if player.pid? and player.updatingerror?
						# failed update player, possibly bad in game name
						delete player.updatingerror
						pid = player.pid
					else
						# true new player
						pid = $scope.newPlayer player
						$scope.allPlayers.push pid
					$scope.markPlayerPresent pid
				@modal.hide()
		$scope.$on 'newEventModal.hide', ->
			$scope.newPlayers.players = []
		
		$scope.attendance =
			modal: $modal
				scope: $scope
				template: 'newevent/getattendance.tpl.html'
				show: false
			data: {}
			loadingmessage: "Please wait while we get your data..."
			errormessage: {}
			loading: false
			show: ->
				@errormessage = {}
				@loading = false
				@data = {}
				@modal.show()
			post: ->
				@loadingmessage = "Please wait while we get attendance data..."
				@loading = true
				$scope.newPlayers.players = []
				$http.post('/api/get-attendance', @data)
					.success (attending) =>
						loadingmessage = "Please wait while we process attendees..."
						$scope.multiFixPlayer = true
						for playerName in attending
							try
								$scope.markPlayerPresent $scope.playerIdByName playerName
							catch
								# the player is not yet added to the system, Yay!
								$scope.newPlayers.players.push
									name: playerName
									inGameName: playerName
									server: 'oce'
						$scope.multiFixPlayer = false
						@modal.hide()
						if $scope.newPlayers.players.length isnt 0 then $scope.newPlayers.show()
						@data = {}
					.error (data, status) =>
						status = status.toString()
						if status is '400' and data.length isnt 0
							@loading = false
							@errormessage = data
						else if status is '404' then window.location.replace '404'
						else if status is '401' or status is '403' then window.location.replace 'login'
						else if status.substring 0, 1 is '5' or status is '403' then window.location.replace 'login'
		
		$scope.shortcutmode = true
		$scope.data = data
		$scope.session = $scope.data.sessions[$routeParams.sessionId]
		$scope.activeTeam = ''
		
		$scope.currentHistory = 
			date: Date.now()
			pairings: angular.copy $scope.session.defaultPairings ? []
		$scope.tempTeams = {}
		$scope.tempTeamsOrder = []
		angular.forEach $scope.session.teams, (team, key) ->
			$scope.tempTeamsOrder.push key
			$scope.tempTeams[key] =
				name: team.name
				players: []
		$scope.activeTeam = $scope.tempTeamsOrder[0]
		
		$scope.tempTeamNameByRef = (tid) -> $scope.tempTeams[tid].name
		_playerFilter = (_searchValue) ->
			(value) ->
				searchValue = $scope[_searchValue]
				searchValue is undefined or
				searchValue.length is 0 or
				-1 isnt $scope.data.players[value].name.toLowerCase().indexOf searchValue.toLowerCase() or
				-1 isnt $scope.data.players[value].inGameName.toLowerCase().indexOf searchValue.toLowerCase()
		$scope.playerFilter = _playerFilter 'playerFilterString'
		
		$scope.allPlayers = []
		angular.forEach $scope.data.players, (player, key) -> $scope.allPlayers.push key
		$scope.presentPlayers = []
		$scope.allPresentPlayers = []
		$scope.markPlayerPresent = (pid) ->
			if $scope.data.players[pid].updatingerror and $scope.data.players[pid].updatingerror isnt '' then $scope.fixPlayer pid
			else
				updatePlayerById pid
				movePlayerById $scope.allPlayers, $scope.presentPlayers, pid
				if -1 is $scope.allPresentPlayers.indexOf pid
					$scope.allPresentPlayers.push pid
					$scope.allPresentPlayers.sort (a,b) -> $scope.playerScoreByRef(a) - $scope.playerScoreByRef b
		$scope.removePlayer = (pid) ->
			movePlayerById $scope.presentPlayers, $scope.allPlayers, pid
			movePlayerById $scope.allPresentPlayers, [], pid
		$scope.addFilteredPlayers = ->
			if $scope.shortcutmode
				pid = $filter('orderBy')($filter('filter')($scope.allPlayers, $scope.playerFilter), $scope.playerNameByRef)[0]
				$scope.markPlayerPresent pid
			else
				angular.forEach ($filter('filter') $scope.allPlayers, $scope.playerFilter)
					,(pid) -> $scope.markPlayerPresent pid
			$scope.playerFilterString = ''
		
		$scope.processPlayers = ->
			angular.forEach $scope.session.teams, (team, key) ->
				angular.forEach team.players, (pid) ->
					if not $scope.data.players[pid].updating and not $scope.data.players[pid].updatingerror? and -1 isnt $scope.presentPlayers.indexOf pid
						$scope.tempTeams[key].players.push pid
						$scope.presentPlayers.splice $scope.presentPlayers.indexOf(pid), 1
			$scope.activeTeam = $scope.tempTeamsOrder[0]
		
		$scope.sortOrder = 1
		# Depreciated for scoreSortOrder
		$scope.getSortOrder = (team) -> (pid) ->
			if $scope.sortOrder is 1 then (if $scope.data.players[pid].updating then 4 else 1) * $scope.leaderFirst(team)(pid) * 1000000 - $scope.playerScoreByRef pid
			else ((if $scope.data.players[pid].updating then 4 else 1) * $scope.leaderFirst(team)(pid)) + $scope.playerNameByRef pid
		
		$scope.scoreSortOrder = (pid) -> (if $scope.data.players[pid].updating then 4 else 1) * 1000000 - $scope.playerScoreByRef pid
		$scope.presentPlayerGroupedClass = (pid) ->
			index = $scope.allPresentPlayers.indexOf pid
			if data.players[pid].updatingerror && data.players[pid].updatingerror != '' then 'alert-danger'
			else if data.players[pid].updating then 'alert-warning'
			else if $scope.playerBracketCount and $scope.playerBracketCount isnt 0 then "present-group-#{parseInt(index / $scope.playerBracketCount) % 14}"
			else ''
		validKeys =
			display: ['q','w','e','r','t','y','u','i','o','p']
			code:	 [81, 87, 69, 82, 84, 89, 85, 73, 79, 80]
		$scope.keyForIndex = (index) ->
			$sce.trustAsHtml if index < 0 or index > 20 then ''
			else '(' + osModifier + ' + ' + (
				if index >= 0 and index < 10 then index + 1
				else if index is 10 then '0'
				else if index > 10 and index < 20 then validKeys.display[index - 11]
			) + ')'
		$scope.indexForKeycode = (code) ->
			if code > 48 and code <= 58 then code - 48 - 1
			else if code is 48 then 9
			else 10 + validKeys.code.indexOf code
		$scope.presentPlayerFilter = _playerFilter 'presentPlayerFilterString'
		$scope.topPresentPlayerId = -> $filter('orderBy')(
			$filter('filter')($scope.presentPlayers, $scope.presentPlayerFilter), $scope.scoreSortOrder
		)[0]
		$scope.topPresentPlayer = -> $scope.data.players[@topPresentPlayerId()]
		$scope.unassign = (pid, tid) -> movePlayerById $scope.tempTeams[tid].players, $scope.presentPlayers, pid
		$scope.assignTeam = (tid, topOnly) ->
			if $scope.shortcutmode or topOnly
				movePlayerById $scope.presentPlayers, $scope.tempTeams[tid].players, $scope.topPresentPlayerId()
			else
				angular.forEach ($filter('filter') $scope.presentPlayers, $scope.presentPlayerFilter)
					,(pid) -> movePlayerById $scope.presentPlayers, $scope.tempTeams[tid].players, pid
			$scope.presentPlayerFilterString = ''
		$scope.addPlayerToActiveTeam = (pid) -> movePlayerById $scope.presentPlayers, $scope.tempTeams[$scope.activeTeam].players, pid
		$scope.totalScore = (team) -> team.players.reduce ((a,b) -> if $scope.data.players[b].updating or $scope.data.players[b].updatingerror then a else a + $scope.data.players[b].scores.aggregate), 0
		$scope.averageScore = (team) -> $scope.totalScore(team) / team.players.length
		$scope.setActiveTeam = (tid) -> $scope.activeTeam = tid
		tempTeams = 0
		$scope.addTeam = ->	
			tempTeams++
			$scope.tempTeamsOrder.push "t_temp#{tempTeams}"
			$scope.tempTeams["t_temp#{tempTeams}"] =
				name: "Temp Team #{tempTeams}"
				players: []
			$scope.activeTeam = "t_temp#{tempTeams}";
		$scope.removeTeam = (tid) ->
			while $scope.tempTeams[tid].players.length > 0
				$scope.presentPlayers.push $scope.tempTeams[tid].players.pop()
			delete $scope.tempTeams[tid]
			if $scope.activeTeam is tid then $scope.activeTeam = $scope.tempTeamsOrder[Math.max 0, -1 + $scope.tempTeamsOrder.indexOf tid]
			$scope.tempTeamsOrder.splice $scope.tempTeamsOrder.indexOf(tid), 1
		
		$scope.finishButtonClass = ->
			if $scope.presentPlayers.length is 0 and $scope.currentHistory.pairings.length <= $scope.tempTeamsOrder.length / 2 then 'btn-success'
			else 'btn-warning'
		$scope.finish  = ->
			refPairings = $scope.currentHistory.pairings
			$scope.currentHistory.pairings = []
			for pair in refPairings
				$scope.currentHistory.pairings.push
					team1:
						id: if pair[0].substring(0, 6) isnt 't_temp' then pair[0] else undefined
						name: $scope.tempTeams[pair[0]].name
						players: $scope.tempTeams[pair[0]].players
					team2: if not pair[1]? then undefined else
						id: if pair[1].substring(0, 6) isnt 't_temp' then pair[1] else undefined
						name: $scope.tempTeams[pair[1]].name
						players: $scope.tempTeams[pair[1]].players
					winner: 0
			$scope.session.history.push $scope.currentHistory
			$location.path("manage/event/#{$routeParams.sessionId}/#{$scope.session.history.length - 1}")
		$scope.placements =
			modal: $modal
				scope: $scope
				template: 'newevent/placements.tpl.html'
				show: false
			availableTeams: []
			setupAvailableTeams: ->
				@availableTeams = []
				@availableTeams.push key for key in $scope.tempTeamsOrder
				for pairing in $scope.currentHistory.pairings
					index1 = @availableTeams.indexOf pairing[0]
					if index1 > -1 then @availableTeams.splice index1, 1
					index2 = @availableTeams.indexOf pairing[1]
					if index2 > -1 then @availableTeams.splice index2, 1
				@modal.show()
			addPairing: -> $scope.currentHistory.pairings.push [undefined,undefined]
			removePairing: (placementIndex) ->
				if $scope.currentHistory.pairings[placementIndex][0]? then @availableTeams.push $scope.currentHistory.pairings[placementIndex][0]
				if $scope.currentHistory.pairings[placementIndex][1]? then @availableTeams.push $scope.currentHistory.pairings[placementIndex][1]
				$scope.currentHistory.pairings.splice placementIndex, 1
			getAvailableTeams: (placementIndex, sideIndex) ->
				currentTeamId = $scope.currentHistory.pairings[placementIndex][sideIndex]
				orderedTeams = $filter('orderBy') @availableTeams, $scope.tempTeamNameByRef
				result = for tid in orderedTeams
					((teamid) =>
						text: "#{$scope.tempTeams[teamid].name}"
						click: =>
							$scope.currentHistory.pairings[placementIndex][sideIndex] = (@availableTeams.splice @availableTeams.indexOf(teamid), 1)[0]
							if currentTeamId? then @availableTeams.push currentTeamId
					) tid
				result.unshift
					text: "Unallocated Teams"
					'class': "nav-header disabled"
				allocatedTeams = []
				for pair in $scope.currentHistory.pairings
					if pair[0]? and pair[0] isnt currentTeamId then allocatedTeams.push pair[0]
					if pair[1]? and pair[1] isnt currentTeamId then allocatedTeams.push pair[1]
				if allocatedTeams.length > 0
					allocatedTeams = $filter('orderBy') allocatedTeams, $scope.tempTeamNameByRef
					result.push
						divider: 'true'
					result.push
						text: "Allocated Teams (swap)"
						'class': "nav-header disabled"
					for tid in allocatedTeams
						result.push ((teamid) =>
							text: "#{$scope.tempTeams[teamid].name}"
							click: =>
								targetPairId = ''
								targetSideId = ''
								for pair, i in $scope.currentHistory.pairings
									if pair[0] is teamid
										targetPairId = i
										targetSideId = 0
										break
									if pair[1] is teamid
										targetPairId = i
										targetSideId = 1
										break
								$scope.currentHistory.pairings[placementIndex][sideIndex] = teamid
								$scope.currentHistory.pairings[targetPairId][targetSideId] = currentTeamId
						) tid
				if $scope.currentHistory.pairings[placementIndex][sideIndex]?
					result.unshift
						divider: 'true'
					result.unshift
						text: "Riot Queue"
						click: =>
							@availableTeams.push $scope.currentHistory.pairings[placementIndex][sideIndex]
							$scope.currentHistory.pairings[placementIndex][sideIndex] = undefined
				result
			cleanPairings: ->
				i = 0
				while i < $scope.currentHistory.pairings.length
					if $scope.currentHistory.pairings[i][0]? and $scope.currentHistory.pairings[i][1]?
						i++
					else if $scope.currentHistory.pairings[i][0]?
						$scope.currentHistory.pairings[i] = [$scope.currentHistory.pairings[i][0]]
						i++
					else if $scope.currentHistory.pairings[i][1]?
						$scope.currentHistory.pairings[i] = [$scope.currentHistory.pairings[i][1]]
						i++
					else
						$scope.currentHistory.pairings.splice i, 1
				return