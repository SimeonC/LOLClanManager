elimination = require "../elimination"
assert = require 'assert'

describe 'elimination', ->
	formats = [
		'((6,(4,5)),((0,1),(2,3)))',#0
		'(((4),(5)),((0,1),(2,3)))',
		'(((4),(5)),((0,1),(2,3)))',#2
		'((6,(4,5)),((0,1),(2,3)))',
		'((6,(4,5)),((0,1),(2,3)))',#4
		'((6,(4,5)),((0,1),(2,3)))',
		'((((0,1),(2,3)),((4,5),(6,7))),(((8,9),(10,11)),((12,13),(14,15))))',#6
		'(0,(1,(2,(3,4))))',
		'((((0,1),2),3),4)'#8
	]
	scores = [
		[[1,1,0],[0],[1,0],[0],[0],[1,1,1],[1,0]],#0
		[[1,1,0],[0],[1,0],[0],[1,0],[1,1,1]],
		[[1,1],[0],[1,0],[0],[1,0],[1,1]],#2
		[[1],[0],[1],[0],[0],[1],[1]],
		[[1],[0],[],[],[0],[1,0],[1,1]],#4
		[[1],[0],[1],[0],[0],[1,1],[1,0]],
		[[1,1,1,1],[0],[1,0],[0],[1,1,0],[0],[1,0],[0],[1,1,1,0],[0],[1,0],[0],[1,1,0],[0],[1,0],[0]],#6
		[[1,1,1,0],[1,1,0],[1,0],[0],[1,1,1,1]],
		[[1,1,1,1],[0],[1,0],[1,1,0],[1,1,1,0]]#8
	]
	correctFullMaps = [
		[[{team1: '6', team2: '6'},{team1: '4', team2: '5'},{team1: '0', team2: '1'},{team1: '2', team2: '3'}],[{team1: '6', team2: '5'},{team1: '0', team2: '2'}],[{team1: '5', team2: '0'}]],
		[[{team1: '4', team2: '4'},{team1: '5', team2: '5'},{team1: '0', team2: '1'},{team1: '2', team2: '3'}],[{team1: '4', team2: '5'},{team1: '0', team2: '2'}],[{team1: '5', team2: '0'}]],
		[[{team1: '4', team2: '4'},{team1: '5', team2: '5'},{team1: '0', team2: '1'},{team1: '2', team2: '3'}],[{team1: '4', team2: '5'},{team1: '0', team2: '2'}],[{team1: '5', team2: '0'}]],
		[[{team1: '6', team2: '6'},{team1: '4', team2: '5'},{team1: '0', team2: '1'},{team1: '2', team2: '3'}],[{team1: '6', team2: '5'},{team1: '0', team2: '2'}],[{team1: 'TBA', team2: 'TBA'}]],
		[[{team1: '6', team2: '6'},{team1: '4', team2: '5'},{team1: '0', team2: '1'},{team1: '2', team2: '3'}],[{team1: '6', team2: '5'},{team1: '0', team2: '0'}],[{team1: '6', team2: 'TBA'}]],
		[[{team1: '6', team2: '6'},{team1: '4', team2: '5'},{team1: '0', team2: '1'},{team1: '2', team2: '3'}],[{team1: '6', team2: '5'},{team1: '0', team2: '2'}],[{team1: '5', team2: 'TBA'}]],
		[[{team1: '0', team2: '1'},{team1: '2', team2: '3'},{team1: '4', team2: '5'},{team1: '6', team2: '7'},{team1: '8', team2: '9'},{team1: '10', team2: '11'},{team1: '12', team2: '13'},{team1: '14', team2: '15'}],[{team1: '0', team2: '2'},{team1: '4', team2: '6'},{team1: '8', team2: '10'},{team1: '12', team2: '14'}],[{team1: '0', team2: '4'},{team1: '8', team2: '12'}],[{team1: '0', team2: '8'}]],
		[[{team1: '0', team2: '0'},{team1: '1', team2: '1'},{team1: '2', team2: '2'},{team1: '3', team2: '4'}],[{team1: '0', team2: '0'},{team1: '1', team2: '1'},{team1: '2', team2: '4'}],[{team1: '0', team2: '0'},{team1: '1', team2: '4'}],[{team1: '0', team2: '4'}]],
		[[{team1: '0', team2: '1'},{team1: '2', team2: '2'},{team1: '3', team2: '3'},{team1: '4', team2: '4'}],[{team1: '0', team2: '2'},{team1: '3', team2: '3'},{team1: '4', team2: '4'}],[{team1: '0', team2: '3'},{team1: '4', team2: '4'}],[{team1: '0', team2: '4'}]]
	]
	describe 'getFullmap', ->
		it "Should calculate the correct results map", ->
			i = 0
			assert.deepEqual elimination.getFullMap(formats[i], scores[i]), correctFullMaps[i], "Fails on complete with round 1 bye [#{i}]"
			i = 1
			assert.deepEqual elimination.getFullMap(formats[i], scores[i]), correctFullMaps[i] , "Fails on incomplete with round 1 bye for 2 teams [#{i}]"
			i = 2
			assert.deepEqual elimination.getFullMap(formats[i], scores[i]), correctFullMaps[i] , "Fails on incomplete with round 1 bye for 1 teams [#{i}]"
			i = 3
			assert.deepEqual elimination.getFullMap(formats[i], scores[i]), correctFullMaps[i] , "Fails on first round only with round 1 bye for 1 teams [#{i}]"
			i = 4
			assert.deepEqual elimination.getFullMap(formats[i], scores[i]), correctFullMaps[i] , "Fails on incomplete round 1 results with round 1 bye for 1 teams [#{i}]"
			i = 5
			assert.deepEqual elimination.getFullMap(formats[i], scores[i]), correctFullMaps[i] , "Fails on incomplete with round 1 bye for 1 teams [#{i}]"
			i = 6
			assert.deepEqual elimination.getFullMap(formats[i], scores[i]), correctFullMaps[i] , "Fails on complete balanced large [#{i}]"
			i = 7
			assert.deepEqual elimination.getFullMap(formats[i], scores[i]), correctFullMaps[i] , "Fails on Left heavy tree [#{i}]"
			i = 8
			assert.deepEqual elimination.getFullMap(formats[i], scores[i]), correctFullMaps[i] , "Fails on right heavy tree [#{i}]"