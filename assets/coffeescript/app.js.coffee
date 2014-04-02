#= require_directory ./app_controllers
#include all the controller logic

#angular logic to go here
osModifier = if navigator.appVersion.indexOf('Mac') > -1 then '&#8984;' else 'CTRL'
module = angular.module 'lolclanmanager', ['ngRoute', 'ngAnimate', 'mgcrea.ngStrap'],
	($routeProvider, $locationProvider) ->
		$routeProvider.otherwise
			templateUrl: 'partials/dashboard'
			controller: DashboardController
		$routeProvider.when '/player/:playerId',
			templateUrl: 'partials/player'
			controller: PlayerController
		$routeProvider.when '/session/:sessionId',
			templateUrl: 'partials/session'
			controller: SessionController
		$routeProvider.when '/team/:sessionId/:teamId',
			templateUrl: 'partials/team'
			controller: TeamController
		$routeProvider.when '/event/:sessionId/:eventId',
			templateUrl: 'partials/event'
			controller: EventController
		$routeProvider.when '/newplayer',
			templateUrl: 'partials/loading'
			controller: NewPlayerController
		$routeProvider.when '/newsession',
			templateUrl: 'partials/loading'
			controller: NewSessionController
		$routeProvider.when '/newteam/:sessionId',
			templateUrl: 'partials/loading'
			controller: NewTeamController
		$routeProvider.when '/newevent/:sessionId',
			templateUrl: 'partials/newevent'
			controller: NewEventController
		$locationProvider.html5Mode true
module.service 'data', ['$http', 'sockets', ($http, sockets) ->
	socket = sockets()
	dataReturn =
		loading: true
	$http.get('/api/load-data')
		.success (data) ->
			dataReturn.loading = false
			angular.extend dataReturn, data
			socket.emit 'set_channel',
				clan_name: data.clan_name
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
socket = io.connect()
socket.on 'notification', (data) ->
	console.log data
module.factory 'sockets', -> (callbacks) ->
	if callbacks?
		if callbacks.playerUpdate? then socket.on 'playerupdate', callbacks.playerUpdate
	socket

class MainController
	constructor: ($scope, data) ->
		$scope.data = data
@MainController = MainController