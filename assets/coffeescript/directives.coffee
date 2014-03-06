'use strict'

module = angular.module 'contestateUtilities', ['hmTouchEvents']

#Curtesy of http://css-tricks.com/snippets/javascript/move-cursor-to-end-of-input/
module.factory 'cuMoveCursorToEnd', -> (el) ->
	if not el.selectionStart? or not el.createtextRange? then el.focus()
	else
		if typeof el.selectionStart == "number" then el.selectionStart = el.selectionEnd = el.value.length
		else if typeof el.createTextRange != "undefined"
			el.focus()
			range = el.createTextRange()
			range.collapse false
			range.select()

#add this to an input field, when enter is pressed in the input field tab is simulated instead
module.directive 'cuNextTabOrderOnEnter', (cuMoveCursorToEnd, cuIsHidden) ->
	compile: ($element, $attrs, transclude) ->
		post: ($scope, $element, $attrs) ->
			$element = $element[0]
			$element.onkeypress = (keyEvent) -> if keyEvent.which is 13 and $element.name isnt 'textarea' and $element.type isnt 'button' and $element.type isnt 'submit'
				keyEvent.stopPropagation()
				keyEvent.preventDefault()
				tabbables = zest("[tabindex]:enabled")
				tabIndex = parseInt($attrs.tabindex)
				tabbables.sort (a,b) -> parseInt(a.tabIndex) - parseInt(b.tabIndex)
				#have to use the key as if we use the tab it's dereferenced from the whole system
				for tab, key in tabbables
					if tabbables[key].tabIndex > tabIndex and not cuIsHidden tabbables[key]
						return cuMoveCursorToEnd tabbables[key]

#copied shamelessly from jQuery
module.factory 'cuIsHidden', ->
	#setup, keeps the vars we use in this factories scope only
	reliableHiddenOffsets = false
	angular.element(document).ready ->
		div = document.createElement "div"
		div.style.width = div.style.paddingLeft = "1px"
		document.body.appendChild div
		div.innerHTML = '<table><tr><td style="display:none"></td><td>t</td></tr></table>'
		reliableHiddenOffsets = div.getElementsByTagName('td')[0].offsetHeight is 0
		document.body.removeChild( div ).style.display = 'none'
	#this is the actual function the factory returns
	(el) ->
		width = el.offsetWidth
		height = el.offsetHeight
		(width is 0 and height is 0) or (not reliableHiddenOffsets and (el.style.display or angular.element(elem).css( "display" )) is "none")

###
	
.tree(elimination-map='eliminationObject', pairingclass='pairing')
	link.pairing-link
		.line-box
	result.pairing-result
		input.name.btn(value="{{players[0][pair.team1]}}")
		input.name.btn(value="{{players[0][pair.team2]}}")
	finalresult.pairing-result
		input.name.btn(value="{{players[0][pair.team1]}}")
	leaf
		.pairing-link
			.line-box
		.input-container
			input.name.btn(value="{{players[0][pair.team1]}}")
			input.name.btn(value="{{players[0][pair.team2]}}")
###

module.directive 'eliminationMap', ($compile) ->
	priority: 1000
	terminal: true
	compile: ($element, $attrs, linker) ->
		($scope, $element, $attrs) ->
			#converts an element from whatever it was to newType (default div) transferring all attributes and content as is
			getConvertedElement = ($element, newType="div") ->
				newEl = angular.element("<#{newType}/>")
				newEl.attr(attr.nodeName, attr.nodeValue) for attr in $element[0].attributes
				newEl.append $element.contents()
				newEl
			
			#appends the $element to the $target after applying the $scope to the $element
			appendWithScope = ($target, scope, $element) ->
				scope.$elementRef = $element
				$compile($element)(scope)
				$target.append $element
				$element
			
			#convenience function, creates a new scope and assigns all the data values to it, note the keys are prefixed with $
			setupScope = ($parentScope, data) ->
				scope = $parentScope.$new()
				for key, value of data
					scope["$#{key}"] = value
				scope
			
			#convert the elements from their custom html tags to divs
			elements =
				link: getConvertedElement $element.find 'linkdiv'
				result: getConvertedElement $element.find 'resultdiv'
				finalresult: getConvertedElement $element.find 'finalresultdiv'
				leaf: getConvertedElement $element.find 'leafdiv'
				tree: $element
				pairing: getConvertedElement $element.find 'pairingdiv'
			
			if $scope.$eval $attrs.eliminationEditable
				angular.element(zest('.add-above', elements.link[0])[0]).attr 'ng-click', 'insertPairing($pairing, $depth, true)'
				angular.element(zest('.add-below', elements.link[0])[0]).attr 'ng-click', 'insertPairing($pairing, $depth, false)'
				$scope.insertPairing = ($pairing, $depth, insertAbove) ->
					#need to add to the format and also insert into the first element array of the map
					#note that this gives us where in the format we have to place the new pairing - also note that we have to add to the fullMap as well...
					elimMap = $scope.$eval $attrs.eliminationMap
					pairing =
						team1: $scope.$eval $attrs.nextPlayerIndex
						team2: $scope.$eval $attrs.nextPlayerIndex
					#insert format position...
					
					#fix byes, so catch n,( or ),n or (n) (outside bracket is implied for side bounded, if we check for it we have to rerun this multiple times)
					format = elimMap.format.replace /([0-9]+),\(/g, '($1,$1),('
					format = format.replace /\),([0-9]+)/g, '),($1,$1)'
					format = format.replace /\(([0-9]+)\)/g, '($1,$1)'#replace end byes
					split = undefined
					end = undefined
					start = undefined
					depth = 0
					pairingCount = 0
					
					for i in [0..format.length-1]
						char = format[i]
						if char is '('
							depth++
							pairingCount *= 2
							if depth is $depth and Math.floor(pairingCount / 2) is $pairing then start = i+1
						else if char is ')'
							pairingCount = Math.floor(pairingCount / 2)
							if depth is $depth and pairingCount is $pairing
								end = i
								break
							depth--
						else if char is ',' and depth is $depth
							if $pairing is Math.floor(pairingCount / 2) then split = i
						if char is ',' then pairingCount++
					
					#need to add the bracket around the OTHER part of the pairing - after the comma
					origFormat = format
					elimMap.format = origFormat.substring(0,start)
					if insertAbove then elimMap.format += "(#{pairing.team1},#{pairing.team2}),(#{origFormat.substring(start,end)})"
					else elimMap.format += "(#{origFormat.substring(start,end)}),(#{pairing.team1},#{pairing.team2})"
					elimMap.format += origFormat.substring end
					
					#then force the update of the whole thing to redraw it!
					elimMap.lastupdate = new Date()
					return
			
			#herein lies the logic and watcher
			if $attrs.pairingclass? then elements.pairing.addClass $attrs.pairingclass
			$scope[$attrs.eliminationMap].lastupdate = new Date()
			$scope.$watch "#{$attrs.eliminationMap}.lastupdate", ->
				#setup the vars for the loop
				elimMap = $scope.$eval $attrs.eliminationMap
				#fix byes, so catch n,( or ),n or (n) (outside bracket is implied for side bounded, if we check for it we have to rerun this multiple times)
				format = elimMap.format.replace /([0-9]+),\(/g, '($1,$1),('
				format = format.replace /\),([0-9]+)/g, '),($1,$1)'
				format = format.replace /\(([0-9]+)\)/g, '($1,$1)'#replace end byes
				elimTree = elimMap.fullMap
				if elimTree? then format = format.replace /[^\(\),]*/g, '' #basically just give us the , and (). Only if we have a full Map to display results from, else we need the player indices
				elements.tree.html '' #clear the elements out of it now we have references
				pairingStack = [elements.tree]
				scopeStack = []
				lastOp = null
				leafOnly = $scope.$eval $attrs.leafOnly
				elimMap.maxDepth = 0
				workingDepth = 0
				for char in format
					if char is '(' then workingDepth++
					else if char is ')' then workingDepth--
					elimMap.maxDepth = Math.max workingDepth, elimMap.maxDepth
				pairingCount = 0
				
				#generate the elements for the tree, looking at the format, fullTreeMap and applying elements from the elements array
				for i in [0..format.length-1]
					char = format[i]
					currentDepth = elimMap.maxDepth - (pairingStack.length - 1)
					if char is '('
						pairingCount *= 2
						lastOp = "open"
						currentPairing = pairingStack[pairingStack.length-1]
						#setup new pairing
						newPairing = elements.pairing.clone()
						currentScope = setupScope($scope, 
							depth: pairingStack.length
							pairing: pairingCount / 2
						)
						#add to the pairing stack and append to previous pairing. It's a Depth First tree traversal so we need to keep track of the path down the current branch
						pairingStack.push newPairing
						scopeStack.push currentScope
						appendWithScope currentPairing, currentScope, newPairing
					else if char is ')'
						pairingStack.pop()
						scopeStack.pop()
						pairingCount = Math.floor pairingCount / 2
						lastOp = "close"
					else if char is ',' #add a pairing, branch merge or leaf
						if elimTree? and elimTree.length > currentDepth and Array.isArray(elimTree[currentDepth]) and elimTree[currentDepth].length > pairingCount / 2 and elimTree[currentDepth][pairingCount / 2]?
							pairing = elimTree[currentDepth][pairingCount / 2]
						else if lastOp is "open" #if it's a leaf!
							team1 = ''
							team2 = ''
							it = i-1
							team1 = format[it--] + team1 while format[it] isnt '('
							it = i+1
							team2 = team2 + format[it++] while format[it] isnt ')'
							pairing =
								team1: team1
								team2: team2
						else 
							pairing =
								team1: 'TBA'
								team2: 'TBA'
						appendWithScope pairingStack[pairingStack.length-1], scopeStack[scopeStack.length-1], elements.link.clone()
						#this logic is for all pairings on the screen, logic is:
						#if (not bye or show byes) AND (last operation was an open bracket (ie a leaf of the tree) or NOT show only leaves (implied from the or that this is not a leaf))
						if (pairing.team1 isnt pairing.team2 and pairing.team1 isnt 'TBA' or $scope.$eval $attrs.showByes) and (lastOp is "open" or not leafOnly)
							#get element to add based on what the last operator is
							targetElement = if lastOp is "open" then elements.leaf.clone() else elements.result.clone()
							#in theory targetElement should == addedElement, this is really just for code clarity
							addedElement = appendWithScope pairingStack[pairingStack.length-1],
								setupScope($scope, 
									depth: pairingStack.length
									pair: pairing
								), targetElement
							#detect a bye - team plays itself so remove team2 display
							if pairing.team1 is pairing.team2 then angular.element(zest('.team2', addedElement[0])[0]).remove()
						#this gives us the final result (which technically shouldn't be displayed as a pairing - compare with scores in the controller to figure which team to display)
						if scopeStack[scopeStack.length-1].$depth is 1
							appendWithScope pairingStack[pairingStack.length-1],
								setupScope($scope, 
									depth: pairingStack.length
									pair: pairing
								), elements.finalresult.clone()
						
						pairingCount++# this is used to track how far down each 'level' we are.
				return

###
 * @ngdoc directive
 * @name ng.directive:ngRepeat
 *
 * @description
 * The `ngRepeat` directive instantiates a template once per item from a collection. Each template
 * instance gets its own scope, where the given loop variable is set to the current collection item,
 * and `$index` is set to the item index or key.
 *
 * Special properties are exposed on the local scope of each template instance, including:
 *
 *   * `$index` Ð `{number}` Ð iterator offset of the repeated element (0..length-1)
 *   * `$first` Ð `{boolean}` Ð true if the repeated element is first in the iterator.
 *   * `$middle` Ð `{boolean}` Ð true if the repeated element is between the first and last in the iterator.
 *   * `$last` Ð `{boolean}` Ð true if the repeated element is last in the iterator.
 *
 *
 * @element ANY
 * @scope
 * @priority 1000
 * @param {repeat_expression} ngRepeat The expression indicating how to enumerate a collection. Two
 *   formats are currently supported:
 *
 *   * `variable in expression` Ð where variable is the user defined loop variable and `expression`
 *     is a scope expression giving the collection to enumerate.
 *
 *     For example: `track in cd.tracks`.
 *
 *   * `(key, value) in expression` Ð where `key` and `value` can be any user defined identifiers,
 *     and `expression` is the scope expression giving the collection to enumerate.
 *
 *     For example: `(name, age) in {'adam':10, 'amalie':12}`.
 *
 * @example
 * This example initializes the scope to a list of names and
 * then uses `ngRepeat` to display every person:
    <doc:example>
      <doc:source>
        <div ng-init="friends = [{name:'John', age:25}, {name:'Mary', age:28}]">
          I have {{friends.length}} friends. They are:
          <ul>
            <li ng-repeat="friend in friends">
              [{{$index + 1}}] {{friend.name}} who is {{friend.age}} years old.
            </li>
          </ul>
        </div>
      </doc:source>
      <doc:scenario>
         it('should check ng-repeat', function() {
           var r = using('.doc-example-live').repeater('ul li');
           expect(r.count()).toBe(2);
           expect(r.row(0)).toEqual(["1","John","25"]);
           expect(r.row(1)).toEqual(["2","Mary","28"]);
         });
      </doc:scenario>
    </doc:example>
###

#sets up the events directly before repeatReorder is executed, as when it executes we no longer have access to the original html until repeats start populating which is bad performance
#all hm events will correctly bubble if you'd like to do something cool like show a delete button with that functionality. Exception is hm-dragup, hm-dragdown and hm-drag when direction is up or down.
module.directive 'cuReorderHandle', ->
	transclude: false
	priority: 999
	terminal: false
	compile: (element, attr, linker) ->
		#setup the element to have correct attributes on the drag 'handle'
		dragElement = angular.element zest(attr.cuReorderHandle, element[0])[0]
		if dragElement?
			#touch compatible events - these do nothing if you don't have angular-hammer installed, so you should. For compatability see here: https://github.com/EightMedia/hammer.js/wiki/Compatibility
			dragElement.attr "hm-drag", "reorderFuncs.moveevent($event, $elementRef, $index)"
			dragElement.attr "hm-dragstart", "reorderFuncs.startevent($event, $elementRef, $index)"
			dragElement.attr "hm-dragend", "reorderFuncs.stopevent($event, $elementRef, $index)"

module.directive 'cuRepeatReorder', ->
	transclude: "element"
	priority: 1000
	terminal: true
	compile: (element, attr, linker) ->
		(scope, iterStartElement, attr) ->
			expression = attr.cuRepeatReorder
			match = expression.match(/^\s*(.+)\s+in\s+(.*)\s*$/)
			lhs = undefined
			rhs = undefined
			valueIdent = undefined
			keyIdent = undefined
			throw Error("Expected ngRepeat in form of '_item_ in _collection_' but got '" + expression + "'.")	unless match
			lhs = match[1]
			rhs = match[2]
			match = lhs.match(/^(?:([\$\w]+)|\(([\$\w]+)\s*,\s*([\$\w]+)\))$/)
			throw Error("'item' in 'item in collection' should be identifier or (key, value) but got '" + lhs + "'.")	 unless match
			valueIdent = match[3] or match[1]
			keyIdent = match[2]
			reorderFuncs = 
				offset: 0
				gesture: 'vertical'
				setMargins: ($element, top="", bottom="") ->
					$element.css "margin-top", top
					$element.css "margin-bottom", bottom
					$element.css "border-top", ""
				
				resetMargins: -> @setMargins lastOrder.peek(c).element for c in scope.$eval(rhs)
				
				updateElementClass: ($element) ->
					if @gesture is "vertical" then $element.addClass 'dragging'
					else $element.removeClass 'dragging'
				
				updateOffset: ($event, $element, $index) ->
					@offset = 0
					collection = scope.$eval(rhs)
					workingDelta = $event.gesture.deltaY
					gDirection = if $event.gesture.deltaY < 0 then "up" else "down"
					directedHeight = $element[0].offsetHeight * if gDirection is "up" then -1 else 1
					workingElement = $element[0]
					halfHeight = 0
					
					workingDelta += directedHeight/2 # This means that the "gap" we will insert into will move when we move past the half way mark of the next element (called lenience calculation)
					while (gDirection is "down" and workingDelta > 0 and $index+@offset < collection.length) or (gDirection is "up" and workingDelta < 0 and $index+@offset >= 0) #figure on how many spaces we've moved
						if gDirection is "down" then @offset++ else @offset--
						if gDirection is "down" and $index+@offset >= collection.length
							workingElement = lastOrder.peek(collection[$index+@offset-1]).element
							break
						if gDirection is "up" and $index+@offset < 0
							workingElement = lastOrder.peek(collection[0]).element
							break
						#get the currently focussed element, then reset the margins on it to 0
						workingElement = lastOrder.peek(collection[$index+@offset]).element
						@setMargins workingElement
						#reset the one on the other side of the original position, if any. This catches if you move really fast across the list
						if collection.length > $index-@offset >= 0 and @offset isnt 0 then @setMargins lastOrder.peek(collection[$index-@offset]).element
						workingDelta += workingElement[0].offsetHeight * if gDirection is "down" then -1 else 1
					#now we have the previous/next element, we insert the correct amount of margin to show the "gap"
					if not (-1 <= @offset <= 1)
						bottomMargin = "#{workingElement.css("margin-bottom").replace(/^[0-9\.]/g, '') + $element[0].offsetHeight}px"
						topMargin = "#{workingElement.css("margin-top").replace(/^[0-9\.]/g, '') + $element[0].offsetHeight}px"
						if gDirection is "up"
							if $index+@offset < 0 then @setMargins workingElement, topMargin
							else @setMargins workingElement, "", bottomMargin
						if gDirection is "down"
							if $index+@offset >= collection.length then @setMargins workingElement, "", bottomMargin
							else @setMargins workingElement, topMargin
					#clear the remaining elements that haven't been reset in the first where
					count = 1 + if $index+@offset < 0 or $index+@offset >= collection.length then 2 else 0 # need to set 2 if at one of the end elements else this code just resets the margins again
					while $index+@offset+count < collection.length or $index+@offset-count >= 0
						if $index+@offset+count < collection.length then @setMargins lastOrder.peek(collection[$index+@offset+count]).element
						if $index+@offset-count >= 0 then @setMargins lastOrder.peek(collection[$index+@offset-count]).element
						count++
					workingDelta -= directedHeight/2 # undo the lenience calculation
					
					#fix the delta so that it cannot move past the first/last slots!
					if (workingDelta <= 0 and gDirection is "down") or (workingDelta >= 0 and gDirection is "up") then delta = $event.gesture.deltaY
					else delta = $event.gesture.deltaY - workingDelta
					if -1 <= @offset <= 1 #close to home so special logic to show the "gap" where we originally are
						@setMargins $element, "#{delta}px", "#{-delta}px" #this means we are hovering over our original position
						beforeIndex = $index-1
						afterIndex = $index+1
					else if @offset < 0 #going up, so show new gap
						if $index > 1 then @setMargins lastOrder.peek(collection[$index-1]).element
						@setMargins $element, "#{delta-$element[0].offsetHeight}px", "#{-(delta+(0.5*$element[0].offsetHeight))}px"
						beforeIndex = $index+@offset
						afterIndex = $index+@offset+1
					else #going down, so show new gap
						if $index < collection.length-2 then @setMargins lastOrder.peek(collection[$index+1]).element
						@setMargins $element, "#{delta-(0*$element[0].offsetHeight)}px", "#{-(delta+$element[0].offsetHeight)}px"
						beforeIndex = $index+@offset-1
						afterIndex = $index+@offset
					# re-add the dragging-before and after classes, the two elements that get these classes border the "gap" we are targeting into
					angular.element(zest(".dragging-before")).removeClass "dragging-before"
					angular.element(zest(".dragging-after")).removeClass "dragging-after"
					if beforeIndex >= 0 then lastOrder.peek(collection[beforeIndex]).element.addClass "dragging-before"
					if afterIndex < collection.length then lastOrder.peek(collection[afterIndex]).element.addClass "dragging-after"
				
				moveevent: ($event, $element, $index) ->
					@updateElementClass $element
					if @gesture is "vertical"
						@updateOffset $event, $element, $index
						$event.preventDefault()
						$event.stopPropagation()
						$event.gesture.stopPropagation()
						return false
					else
						@resetMargins()
				
				startevent: ($event, $element, $index) ->
					$element.parent().addClass "active-drag-below"
					#we get the gesture ONCE then continue using it forever till the end
					@gesture = if $event.gesture.direction is "up" or $event.gesture.direction is "down" then "vertical" else "horizontal"
					@updateElementClass $element
					@offset = 0
					@updateOffset $event, $element
					$event.preventDefault()
				
				stopevent: ($event, $element, $index) ->
					$element.parent().removeClass "active-drag-below"
					@resetMargins()
					angular.element(zest(".dragging-before")).removeClass "dragging-before"
					angular.element(zest(".dragging-after")).removeClass "dragging-after"
					#after animation, so before the watch is fired!
					if @offset isnt 0
						collection = scope.$eval(rhs)
						obj = collection.splice $index, 1
						if @offset < 0 then collection.splice $index + @offset + 1, 0, obj[0]
						else if @offset > 0 then collection.splice $index + @offset - 1, 0, obj[0]
					#so it shouldn't dissapear during transition
					$element.removeClass 'dragging'
					$event.preventDefault()
			
			# Store a list of elements from previous run. This is a hash where key is the item from the
			# iterator, and the value is an array of objects with following properties.
			#		- scope: bound scope
			#		- element: previous element.
			#		- index: position
			# We need an array of these objects since the same object can be returned from the iterator.
			# We expect this to be a rare case.
			lastOrder = new HashQueueMap()
			scope.$watch ngRepeatWatch = (scope) ->
				index = undefined
				length = undefined
				collection = scope.$eval(rhs)
				cursor = iterStartElement # current position of the node
				# Same as lastOrder but it has the current state. It will become the
				# lastOrder on the next iteration.
				nextOrder = new HashQueueMap()
				arrayBound = undefined
				childScope = undefined
				key = undefined
				value = undefined
				array = undefined
				last = undefined
				# key/value of iteration
				# last object information {scope, element, index}
				unless isArray(collection)
					
					# if object, extract keys, sort them and use to determine order of iteration over obj props
					array = []
					for key of collection
						array.push key	if collection.hasOwnProperty(key) and key.charAt(0) isnt "$"
					array.sort()
				else
					array = collection or []
				arrayBound = array.length - 1
				
				# we are not using forEach for perf reasons (trying to avoid #call)
				index = 0
				length = array.length

				while index < length
					key = (if (collection is array) then index else array[index])
					value = collection[key]
					last = lastOrder.shift(value)
					if last
						
						# if we have already seen this object, then we need to reuse the
						# associated scope/element
						childScope = last.scope
						nextOrder.push value, last
						if index is last.index
							
							# do nothing
							cursor = last.element
						else
							
							# existing item which got moved
							last.index = index
							
							# This may be a noop, if the element is next, but I don't know of a good way to
							# figure this out,	since it would require extra DOM access, so let's just hope that
							# the browsers realizes that it is noop, and treats it as such.
							cursor.after last.element
							cursor = last.element
					else
						
						# new item which we don't know about
						childScope = scope.$new()
					childScope[valueIdent] = value
					childScope[keyIdent] = key	if keyIdent
					childScope.$index = index
					childScope.$first = (index is 0)
					childScope.$last = (index is arrayBound)
					childScope.$middle = not (childScope.$first or childScope.$last)
					childScope.reorderFuncs = reorderFuncs
					unless last
						linker childScope, (clone) ->#clone is a copy of the original element, thanks to transclude
							cursor.after clone #this puts the repeated element on the page
							last =
								scope: childScope
								element: (cursor = clone)
								index: index
							childScope.$elementRef = last.element
							nextOrder.push value, last

					index++
				
				#shrink children
				for key of lastOrder
					if lastOrder.hasOwnProperty(key)
						array = lastOrder[key]
						while array.length
							value = array.pop()
							value.element.remove() #this removes the old element off the page
							value.scope.$destroy()
				lastOrder = nextOrder
				return #need this otherwise it errors

###
 * A map where multiple values can be added to the same key such that they form a queue.
 * @returns {HashQueueMap}
###
HashQueueMap = ->
HashQueueMap:: =
	
	###
	Same as array push, but using an array as the value for the hash
	###
	push: (key, value) ->
		array = this[key = hashKey(key)]
		unless array
			this[key] = [value]
		else
			array.push value

	
	###
	Same as array shift, but using an array as the value for the hash
	###
	shift: (key) ->
		array = this[key = hashKey(key)]
		if array
			if array.length is 1
				delete this[key]

				array[0]
			else
				array.shift()

	
	###
	return the first item without deleting it
	###
	peek: (key) ->
		array = this[hashKey(key)]
		array[0]	if array

isArray = (value) -> toString.apply(value) is '[object Array]'
hashKey = (obj) ->
	objType = typeof obj
	key = undefined
	if objType is "object" and obj isnt null
		if typeof (key = obj.$$hashKey) is "function"
			
			# must invoke on object to keep the right this
			key = obj.$$hashKey()
		else key = obj.$$hashKey = nextUid()	if key is `undefined`
	else
		key = obj
	objType + ":" + key

uid = ["0", "0", "0"]

nextUid = ->
	index = uid.length
	digit = undefined
	while index
		index--
		digit = uid[index].charCodeAt(0)
		if digit is 57 #'9'
			uid[index] = "A"
			return uid.join("")
		if digit is 90 #'Z'
			uid[index] = "0"
		else
			uid[index] = String.fromCharCode(digit + 1)
			return uid.join("")
	uid.unshift "0"
	uid.join ""