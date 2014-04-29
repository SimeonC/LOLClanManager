angular.module 'lolapp-modules'
	.directive 'betterPlaceholder', ->
		restrict: 'AC'
		require: 'ngModel'
		link: (scope, element, attrs, ngModel) ->
			origPlaceholderText = attrs.placeholder
			placeholder = '<span class=\"help-block better-placeholder-text\">' + attrs.placeholder + '</span>'
			
			# watch our model for changes
			scope.$watch attrs.ngModel, (newValue, oldValue) ->
				return if newValue is oldValue
				if newValue is "" then element.attr 'placeholder', ''
				else if not element.hasClass 'better-placeholder-active'
					element.before placeholder
					element.addClass 'better-placeholder-active'
			# remove the placeholder, and set the default placeholde to blank since we already have one
			element.on 'blur', ->
				if element.val() is ""
				element.prev().remove()
				element.removeClass 'better-placeholder-active'
				element.attr 'placeholder', origPlaceholderText
	.directive 'httpValidation', ['$timeout', '$compile', ($timeout, $compile) ->
		restrict: 'A'
		require: 'ngModel'
		link: (scope, element, attrs, ngModel) ->
			waiting = undefined
			scope.pendingHttp = -> ngModel.$error.pendingHttp
			scope.$valid = -> ngModel.$valid
			scope.$invalid = -> ngModel.$invalid
			scope.$dirty = -> ngModel.$dirty
			if attrs.showIcons
				element.$parent().addClass 'has-feedback'
				element.after $compile('<i class="fa fa-spinner fa-spin form-control-feedback" ng-show="pendingHttp()"></i>') scope
				element.after $compile('<i class="fa fa-check-circle-o form-control-feedback" ng-show="!pendingHttp() && $dirty() && $valid()"></i>') scope
				element.after $compile('<i class="fa fa-times-circle-o form-control-feedback" ng-show="!pendingHttp() && $dirty() && $invalid()"></i>') scope
			if attrs.messages?
				if scope.$parent[attrs.messages]? then scope.messages = scope.$parent[attrs.messages]
				else scope.messages = scope.$parent.$eval attrs.messages
				element.after $compile("<span class='help-block' ng-show='!pendingHttp() && $dirty() && $valid()' ng-bind='messages.success'/>") scope
				element.after $compile("<span class='help-block' ng-show='!pendingHttp() && $dirty() && $invalid()' ng-bind='messages.failure'/>") scope
				element.after $compile("<span class='help-block' ng-show='pendingHttp()' ng-bind='messages.pending'/>") scope
			# show-icons='true' messages="errorMsg.ingamename"
			ngModel.$setValidity 'http', true
			ngModel.$parsers.unshift (value) ->
				if waiting? then $timeout.cancel waiting
				if ngModel.$isEmpty value
					ngModel.$setValidity 'http', false
					delete ngModel.$error 'pendingHttp'
				else
					ngModel.$setValidity 'pendingHttp', true
					waiting = $timeout ->
						_data = {}
						if attrs.additionalParams? then angular.extend _data, scope.$parent.$eval attrs.additionalParams
						_data.value = value
						$http.post(attrs.httpValidation, _data)
							.success (valid) ->
								ngModel.$setValidity 'http', valid
								delete ngModel.$error 'pendingHttp'
						waiting = undefined
					, 1000 # wait 1 second for changes to stop
				undefined
				
	]
.directive 'dropSelect', ['$compile', '$window', '$animate', '$timeout', ($compile, $window, $animate, $timeout) ->
	restrict: 'AC'
	require: 'ngModel'
	scope:
		dropSelect: '='
		value: '=ngModel'
	transclude: true
	link: (scope, element, attrs, ngModel, $transclude) ->
		drop = undefined
		selected = undefined
		open = false
		bodyEl = angular.element $window.document.body
		bodyClick = (e) -> if e.target isnt element[0] then e.target isnt element[0] and $hide()
		$transclude scope, (clone) ->
			element.html('')
			element.append clone
			element.append '&nbsp;<span class="caret"></span>'
		
		setupOption = (value) ->
			childScope = scope.$new()
			childScope.value = value
			$transclude childScope, (clone) ->
				# SHHHHHH.... the ng-click doesn't do nything...
				_element = angular.element $compile('<li><a ng-click="selectElement(value)"></a></li>') childScope
				if ngModel.$modelValue is value then selected = _element
				_element.find('a').append clone
				drop.append _element
				_element.on 'click', ->
					scope.$parent.$apply -> ngModel.$setViewValue value
					$hide()
		
		selectOption = (_select) ->
			if _select?
				$animate.removeClass selected, 'active'
				selected = _select
			if selected?
				$animate.addClass selected, 'active'
				drop.css 'top', "-#{selected[0].offsetTop}px"
		
		$show = ->
			scope.$parent.$apply ->
				drop = angular.element '<ul class="dropdown-menu show" role="menu"></ul>'
				setupOption option for option in scope.dropSelect
				$animate.enter drop, null, angular.element element
				selectOption()
				open = true
				$timeout ->
					bodyEl.on 'click', bodyClick
					bodyEl.on 'keydown', keyDown
		$hide = ->
			open = false
			bodyEl.off 'click', bodyClick
			bodyEl.off 'keydown', keyDown
			$animate.leave drop
		
		element.on 'click', (e) ->
			# show dropdown
			e.preventDefault()
			e.stopPropagation()
			$show()
			false
		
		element.on 'focus', -> $show()
		element.on 'keydown', (event) ->
			code = e.keyCode or e.which
			if code is 9 or code is 13 or (code >= 37 and code <= 40) then $show()
		keyDown = (e) ->
			code = e.keyCode or e.which
			if code is 27 then $hide()
			else if code is 9 or code is 13 #tab key or enter key
				for option, index in scope.dropSelect
					if option is selected.scope().value
						scope.$parent.$apply -> ngModel.$setViewValue selected.scope().value
						break
				$hide()
				if code is 13 then e.preventDefault()
			else if code is 37 or code is 38 # left or up
				prev = undefined
				children = selected.parent().children()
				for child, i in children
					if child is selected[0]
						prev = angular.element children[i-1]
						break
				if prev? then selectOption prev
			else if code is 39 or 40
				if selected.next().length > 0 then selectOption selected.next()
]