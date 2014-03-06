#angular logic to go here

module = angular.module 'contestate', ['hmTouchEvents', 'ngStorage', 'contestateUtilities']

class newcontest
	constructor: ($scope, $timeout, cuMoveCursorToEnd, $localStorage, $sessionStorage) ->
		#load from session storage if needed
		$scope.session =
			players: if not $sessionStorage.players? then [[],[]] else $sessionStorage.players
			contesttype: if not $sessionStorage.contesttype? then 'elimination' else $sessionStorage.contesttype
		$scope.contesttypes = ['scorecard','elimination','roundrobin']
		$scope.tempplayer = ['','']
		
		$scope.$watch 'session.contesttype', ->
			$scope.session.players = if $scope.session.contesttype is 'elimination' then [['','']] else [[],[]] #reset on change
			$scope.eliminationObjectCreate.format = '(0,1)'
		
		$scope.nextStep = ->
			$sessionStorage = $scope.session
		
		$scope.updatePlayers = (playerIndex) ->
			$scope.hideDeletes()
			if $scope.tempplayer[playerIndex] is "" then return
			$scope.session.players[playerIndex].push
				val: $scope.tempplayer[playerIndex]
			$scope.tempplayer[playerIndex] = ""
			$timeout ->
				cuMoveCursorToEnd zest("#players#{playerIndex} input.player.last-player")[0]
			, 1
		
		$scope.setContesttype = (ct) -> $scope.session.contesttype = ct
		
		$scope.hideDeletes = (exclude) ->
			for el in zest(".width-hide.show > .btn")
				element = angular.element(el)
				if not angular.equals element.parent(), exclude
					element.parent().removeClass "show"
		
		$scope.showDelete = ($event) ->
			target = angular.element($event.target).next()
			$scope.hideDeletes target
			target.addClass "show"
			$event.preventDefault()
			$event.stopPropagation()
			$event.gesture.stopPropagation()
		
		$scope.deletePlayer = (playerIndex, $index) -> $scope.session.players[playerIndex].splice $index, 1
		
		deletedIndices = []
		$scope.nextPlayerIndex = ->
			indice = $scope.players.length
			if deletedIndices.length isnt 0 then indice = deletedIndices.pop()
			$scope.players[0].push $scope.players.length
			indice
		
		$scope.pairWinner = (pair) -> 'He Won!'
		$scope.playerValue = (playerID) -> playerID #if playerID is 'TBA' then playerID else $scope.players[playerID]
		
		$scope.checkForPlayerDelete = (playerIndex, $index) ->
			#hide all delete buttons
			$scope.hideDeletes()
			if $scope.session.players[playerIndex][$index].val is ''
				$scope.session.players[playerIndex].splice $index, 1
				$timeout ->
					cuMoveCursorToEnd if $index is 0 then zest("#players#{playerIndex} .input-wrap input")[0] else zest("#players#{playerIndex} .input-wrap:nth-child(#{$index+1}) + .input-wrap input")[0]
				, 1
		
		$scope.eliminationObjectCreate =
			format: '(0,1)'
		
@newcontest = newcontest