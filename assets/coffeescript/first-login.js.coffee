firstlogin = angular.module 'firstlogin', []

firstlogin.controller 'Controller', ($scope, $http, $location, $timeout) ->
	$scope.data =
		appname: ''
		server: 'oce'
	
	$scope.servers =
		oce: "Oceania"
		na: "North America"
	
	$scope.appId = ->
		if not $scope.data.appname? then ''
		else
			$scope.data.appname
				.replace /[ ]/g, '-'
				.replace /[^a-zA-Z0-9_]*/g, ''
				.toLowerCase()
	
	$scope.dispurl = ->
		(if @appId() is '' then "#{$location.absUrl().replace 'first-login', '{Enter Application Name}'}/"
		else "#{$location.absUrl().replace 'first-login', $scope.appId()}/").replace /(#|\?).*/, ''
	
	$scope.checkingApp = false
	
	waiting = undefined
	$scope.checkUnique = ->
		if waiting? then $timeout.cancel waiting
		if $scope.data.appname?
			$scope.checkingApp = true
			waiting = $timeout ->
				$http.post('/api/unique-app', {id: $scope.appId()})
					.success (data) ->
						$scope.setupform.appname.$setValidity 'uniqueapp', data.valid
						$scope.checkingApp = false
				waiting = undefined
			, 1000 # wait 1 second for changes to stop
		else $scope.checkingApp = false
	
	$scope.saving = false
	$scope.savingmessage = ''
	$scope.save = ->
		$scope.savingmessage = "Setting up #{$scope.data.appname}"
		$scope.saving = true
		$http.post('/api/setup',
			server: $scope.data.server
			appname: $scope.data.appname
			appid: $scope.appId()
		).success (data) ->
			$scope.savingmessage = "Loading #{$scope.data.appname}"
			if data.success then document.location.href = "/#{$scope.appId()}/manage"
			else alert 'ERROR'
			