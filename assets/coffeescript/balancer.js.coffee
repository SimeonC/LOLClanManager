#angular logic to go here

module = angular.module 'lolbalancer', []

class balancer
	constructor: ($scope, $http) ->
		$scope.players = ({url:u} for u in ['http://loldb.gameguyz.com/analyze/default/index/200067185/9/323308','http://loldb.gameguyz.com/analyze/default/index/200009135/9/234115','http://loldb.gameguyz.com/analyze/default/index/200082143/9/330762','http://loldb.gameguyz.com/analyze/default/index/200086594/9/343045','http://loldb.gameguyz.com/analyze/default/index/200082221/9/330730','http://loldb.gameguyz.com/analyze/default/index/200524283/9/963960','http://loldb.gameguyz.com/analyze/default/index/200522867/9/973931','http://loldb.gameguyz.com/analyze/default/index/200331905/9/691200','http://loldb.gameguyz.com/analyze/default/index/200532041/9/934647','http://loldb.gameguyz.com/analyze/default/index/200090807/9/345086'])
		$scope.result =
			confidence: 0
			teams: []
		$scope.crunchNumbers = ->
			$http.post('/balance-teams',
				players: $scope.players
			).success (data) -> $scope.result = data
		$scope.confidenceDisplay = ->
			if $scope.result.confidence > 0 then "Team favoured to win by #{parseInt Math.abs $scope.result.confidence * 100}% > "
			else if $scope.result.confidence < 0 then " < Team favoured to win by #{parseInt Math.abs $scope.result.confidence * 100}%"
			else 'Calculate Results first'
@balancer = balancer