#= require_directory ./app_controllers
#include all the controller logic

#angular logic to go here
osModifier = if navigator.appVersion.indexOf('Mac') > -1 then '&#8984;' else 'CTRL'
privatesocket = io.connect 'http://tawmanager.localhost:3000/private'
publicsocket = io.connect 'http://tawmanager.localhost:3000/public'
module = angular.module 'lolclanmanager', ['ngRoute', 'ngAnimate', 'mgcrea.ngStrap'],
	($routeProvider, $locationProvider) ->
		$routeProvider.otherwise
			templateUrl: '/partials/dashboard'
			controller: DashboardController
		$routeProvider.when '/manage/player/:playerId',
			templateUrl: '/partials/player'
			controller: PlayerController
		$routeProvider.when 'manage/session/:sessionId',
			templateUrl: '/partials/session'
			controller: SessionController
		$routeProvider.when 'manage/team/:sessionId/:teamId',
			templateUrl: '/partials/team'
			controller: TeamController
		$routeProvider.when 'manage/event/:sessionId/:eventId',
			templateUrl: '/partials/event'
			controller: EventController
		$routeProvider.when 'manage/newplayer',
			templateUrl: '/partials/loading'
			controller: NewPlayerController
		$routeProvider.when 'manage/newsession',
			templateUrl: '/partials/loading'
			controller: NewSessionController
		$routeProvider.when 'manage/newteam/:sessionId',
			templateUrl: '/partials/loading'
			controller: NewTeamController
		$routeProvider.when 'manage/newevent/:sessionId',
			templateUrl: '/partials/newevent'
			controller: NewEventController
		$routeProvider.when 'manage/settings',
			templateUrl: '/partials/settings'
			controller: SettingsController
		$locationProvider.html5Mode true

module.service 'getAppId', ['$document', ($document) ->
	-> $document.find('base').attr('href').replace /\//g, ''
]

module.service 'data', ['$http', 'getAppId', ($http, getAppId) ->
	dataReturn =
		loading: true
	appId = getAppId()
	$http.get('/api/load-data/' + appId)
		.success (data) ->
			dataReturn.loading = false
			angular.extend dataReturn, data
			dataReturn.allPlayers = []
			dataReturn.allPlayers.push key for key of data.players
			privatesocket.emit 'joinroom',
				room: appId
			publicsocket.emit 'joinroom',
				room: appId
		.error (data, status) ->
			status = status.toString()
			if status is '404' then window.location.replace '404'
			else if status is '401' or status is '403' then window.location.replace 'login'
			else if status.substring 0, 1 is '5' or status is '403' then window.location.replace 'login'
				
	dataReturn
]

module.factory 'sharedFuncs', -> ($scope) ->
	leaderFirst: (team) -> (pid) ->
		if team? and team.leader? and team.leader is pid then 0
		else if $scope.data.players[pid].leader then 1
		else 2
	playerNameByRef: (pid) -> $scope.data.players[pid].name
	playerScoreByRef: (pid) -> if $scope.data.players[pid].updating or $scope.data.players[pid].updatingerror then 0 else parseInt $scope.data.players[pid].scores.aggregate
	playerIdByName: (name) ->
		name = name.toLowerCase()
		for pid, player of $scope.data.players
			if player.name.toLowerCase() is name then return pid
		throw "No Player with name #{name} found"
	formClass: (form, name) ->
		'has-success': form[name].$dirty && form[name].$valid
		'has-error': form[name].$invalid
	newPlayer: (player) ->
		pid = "p#{Math.random() * 1000000000000000000}"
		player.pid = pid
		$scope.data.players[pid] = player
		$scope.data.allPlayers.push pid
		pid
module.factory 'sockets', ($rootScope, data) -> (callbacks) ->
	publicsocket.on 'playerupdate', (resp) ->
		$rootScope.$apply ->
			resp.player.updating = false
			if not resp.localonly
				# handle new player being updated through
				if not data.players[resp.player.pid]? then data.players[resp.player.pid] = resp.player
				else
					delete data.players[resp.player.pid].updatingerror
					angular.extendDeep data.players[resp.player.pid], resp.player
			if callbacks? and callbacks.playerUpdate? then callbacks.playerUpdate resp.player
	publicsocket.on 'playerupdatestarted', (resp) ->
		$rootScope.$apply ->
			if data.players[resp.pid]?
				data.players[resp.pid].updating = true
				delete data.players[resp.pid].updatingerror
				if callbacks? and callbacks.playerupdatestarted? then callbacks.playerupdatestarted resp.pid
	
	publicsocket: publicsocket
	privatesocket: privatesocket

class NavController
	constructor: ($scope, data, sharedFuncs, sockets, getAppId) ->
		angular.extend $scope, sharedFuncs($scope)
		$scope.data = data
		$scope.appId = getAppId()
@NavController = NavController

class MainController
	constructor: ($scope, data, sharedFuncs) ->
		angular.extend $scope, sharedFuncs($scope)
		$scope.data = data
@MainController = MainController