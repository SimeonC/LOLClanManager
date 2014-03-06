"Use Strict"
#This is an approximation algorithm for sorting 10 players into 5 roles on 2 teams. It currently has a 99.9% success rate when running with the default tolerance of a 10% difference between teams.
exports = module.exports =
	multiteambalance: (players=[], fixedteams=[]) ->
		totalScore = 0
		totalPlayers = 0
		do =>
			_countScore = (player) ->
				player.score = parseInt player.score
				totalScore += player.score
				totalPlayers++;
			_countScore player for player in players
			_countScore player for player in team for team in fixedteams
		averageScore = parseInt totalScore / totalPlayers
		
		teamCount = Math.ceil tetolPlayers / 5
		
		if fixedteams.length > teamCount
			players.splice 0, 0, (fixedteams.splice teamCount - fixedteams.length, fixedteams.length - teamCount).reduce ((a,b) -> a.splice 0, 0, b), []
		
		# if teams is odd we have a throwaway team or 2
		fixedteamplayers = fixedteams.reduce ((a,b) -> a + b.length), 0
		if ((players.length + fixedteamplayers) / 5) % 1 isnt 0
			_teamCount = Math.floor (players.length + fixedteamplayers) / 5
			_teamCount = _teamCount - _teamCount % 2
			playersIn = (_teamCount * 5) - Math.min _teamCount, fixedteamplayers
			# sorts most average person first - outliers last
			players.sort (a,b) -> Math.abs(averageScore - a.score) - Math.abs(averageScore - b.score)
			outlierPlayers = players[playersIn..]
			players = players[0...playersIn]
		
		teamCount = Math.floor (players.length + fixedteamplayers.length) / 5
		
		teams = []
		for t in fixedteams
			teams.push
				team: t
				score: t.reduce ((a,b) -> a + b.score), 0
				locked: t.length is 5
		
		#sort highest to lowest average score
		teams.sort (a,b) -> (b.score/b.team.length) - (a.score/a.team.length)
		
		# construct average difference matrices
		averageTeamDifference = []
		for teamI, i in teams
			averageTeamDifference.push []
			for teamJ, j in teams
				averageTeamDifference[i][j] = parseInt(teamI.score / teamI.team.length) - parseInt(teamJ.score / teamJ.team.length)
		
		# this constructs a matrices such that adding player i to team a and j to team b means that the difference between team b and a's scores (b - a) is changed by playerDifference[i][j]
		playerDifference = []
		for pI, i in players
			playerDifference.push []
			for pJ, j in players
				playerDifference[i][j] = if i is j then pI.score else pJ.score - pI.score
		
		
		
		if teams.length > teamCount
			outlierTeams = teams.splice teamCount-1, teams.length - teamCount
			if outlierTeams.length < outlierPlayers.length / 5 then outlierTeams.push []
		
		players.sort (a,b) -> b.score - a.score
		
		teamIndex = teams.length - 1
		goingUp = false
		for player in players
			if not teams[teamIndex] then teams[teamIndex] = [player]
			else teams[teamIndex].push player
			if goingUp
				if teamIndex is teams.length - 1 then goingUp = false
				else teamIndex++
			else
				if teamIndex is 0 then goingUp = true
				else teamIndex--
		
		# estimate current balance, also sort by highest scored to lowest. This should give the best estimate
		teams.sort (a,b) -> (b.reduce ((a,b) -> a + b.score), 0) - (a.reduce ((a,b) -> a + b.score), 0)
		
		totals = ((team.reduce ((a,b) -> a + b.score), 0) for team in teams)
		games = []
		for i in [0...teams.length] when i % 2 is 0
			if not teams[i].locked and not teams[i+1].locked
				{teams: [_team1, _team2], confidence} = @noprefbalance [teams[i].team, teams[i+1].team]
			else
				_team1 = teams[i]
				_team2 = teams[i+1]
				confidence = @percentDiff teams[i].reduce(((a,b) -> a + b.score), 0), teams[i+1].reduce(((a,b) -> a + b.score), 0)
			games.push
				team1: _team1
				team2: _team2
				confidence: @percentDiff _team1 = (teams[i].reduce ((a,b) -> a + b.score), 0), _team2 = (teams[i+1].reduce ((a,b) -> a + b.score), 0)
				_confidence: confidence
				team1percent: _team1 / (_team1+_team2)
				team2percent: _team2 / (_team1+_team2)
		
		if outlierTeams?
			for team, i in outlierTeams
				if uncaptained[i] then team.sort (a,b) -> b.score - a.score
				games.push
					team1: team
					team2: []
					confidence: '?'
					team1percent: '?'
					team2percent: '?'
		
		games
	
	#this function takes in a teamscores[team 0 total score, team 1 total score], teams[[array of team 0 players],[array of team 2 players]], swaps[[team 0 index, team 1 index]]
	#This function modifies the passed in referenced teams to swap the indicated players over and returns the finalteam scores IF the total change will make the team score difference smaller
	noprefmultiswapplayers: (teamscores, teams, swaps, debug=false) ->
		#first generate all of the correct data and setup variables
		if debug then console.log swaps
		finalscores = [teamscores[0], teamscores[1]]
		if debug then console.log teams
		#get the swap scores
		swapscores = for si of swaps
			for sj of swaps[si]
				teams[1-sj][swaps[si][1-sj]].score
		
		#NB: This particular version assumes there are no swapping paths/loops in the passed logic all indices in swaps MUST be unique
		if debug then console.log "swap [0][#{swaps[0][0]}] = #{teams[0][swaps[0][0]].score} -> #{swapscores[0][0]} for [1][#{swaps[0][1]}] = #{teams[1][swaps[0][1]].score} -> #{swapscores[0][1]} if #{0} < #{-1 * (swapscores.reduce(((a,b) -> a + (b[1] - b[0])), 0)/(teamscores[1] - teamscores[0]))} <= #{0.5}"
		#if we are close to half the difference, sum the differences. The reduce adds together the multiple swaps)
		if 0 < -1 * (swapscores.reduce(((a,b) -> a + (b[1] - b[0])), 0)/(teamscores[1] - teamscores[0])) <= 0.5
			if debug then console.log "swap!"
			# This amends the finalscores based on the swaps; these 1 reductions replace the single version of: targetRoleScores[1] - @playerRoleScore teams[1][team2index]
			finalscores[0] += swaps.reduce(((a,b,i) => a + (swapscores[i][0] - teams[0][b[0]].score)), 0)
			finalscores[1] += swaps.reduce(((a,b,i) => a + (swapscores[i][1] - teams[1][b[1]].score)), 0)
			
			#swap players over teams
			for s in swaps
				tempTeam = teams[0][s[0]]
				teams[0][s[0]] = teams[1][s[1]]
				teams[1][s[1]] = tempTeam
		finalscores #don't need to return teams as it's an array reference
	
	noprefbalance: (teams, tolerance=0.1, debug=false) ->
		sums = [teams[0].reduce(((a,b) -> a + b.score), 0), teams[1].reduce ((a,b) -> a + b.score), 0]
		
		if Math.abs(@percentDiff sums[0], sums[1]) > tolerance #bad case - means teams are more than tolerance apart
			#now time to try match up the shortfall, negative means that team 0 has higher skill score, positive team 1 has higher skill
			if debug then console.log "******** Do SORT ******** for tolerance #{tolerance}"
			if debug then console.log "---------- Step 1 -  Difference is #{Math.abs @percentDiff sums[0], sums[1]}, sums are: #{sums[0]}, #{sums[1]}"
			sidesSwapped = true
			count = 0
			while sidesSwapped and not (0 < Math.abs(@percentDiff sums[0], sums[1]) <= tolerance) and count < 20
				count++
				sidesSwapped = do =>
					result = false
					for t of teams
						for i of teams[t]
							tempsums = @noprefmultiswapplayers sums, teams, [[i, i]]
							#tempsums = swapplayers sums, teams, i, i, tolerance
							if tempsums[0] isnt sums[0] or tempsums[1] isnt sums[1] then result = true
							sums = tempsums
							if 0 < Math.abs(@percentDiff sums[0], sums[1]) <= tolerance then result
					result
			#second reduction if necessary
			if debug then console.log "---------- Step 2 -  Difference is #{Math.abs @percentDiff sums[0], sums[1]}, sums are: #{sums[0]}, #{sums[1]}"
			if Math.abs(@percentDiff sums[0], sums[1]) > tolerance
				do =>
					#in here we attempt to mess up the teams a bit to get some balance if possible
					sidesSwapped = true
					count = 0
					while sidesSwapped and not (0 < Math.abs(@percentDiff sums[0], sums[1]) <= tolerance) and count < 50
						count++
						sidesSwapped = false
						for i of teams[0]
							for j of teams[1]
								#tempsums = swapplayers sums, teams, i, j, tolerance
								tempsums = @noprefmultiswapplayers sums, teams, [[i, j]]
								if tempsums[0] isnt sums[0] or tempsums[1] isnt sums[1] then sidesSwapped = true
								sums = tempsums
								if 0 < Math.abs(@percentDiff sums[0], sums[1]) <= tolerance then return
				if Math.abs(@percentDiff sums[0], sums[1]) > tolerance
					#now we are getting into the nasty section - here we have to try swap more than one role pairing at a time...
					if debug then console.log "---------- Step 3: Double swaps -  Difference is #{Math.abs @percentDiff sums[0], sums[1]}, sums are: #{sums[0]}, #{sums[1]}"
					do =>
					#in here we attempt to mess up the teams a bit to get some balance if possible
						sidesSwapped = true
						count = 0
						while sidesSwapped and not (0 < Math.abs(@percentDiff sums[0], sums[1]) <= tolerance) and count < 100
							count++
							sidesSwapped = true
							for i in [0..teams[0].length-2]
								for i2 in [parseInt(i)+1..teams[0].length-1]
									for j in [0..teams[1].length-2]
										for j2 in [parseInt(j)+1..teams[1].length-1]
											tempsums = @noprefmultiswapplayers sums, teams, [[i,j],[i2,j2]]
											if tempsums[0] isnt sums[0] or tempsums[1] isnt sums[1] then sidesSwapped = true
											sums = tempsums
											if 0 < Math.abs(@percentDiff sums[0], sums[1]) <= tolerance then return
		if debug then console.log "Completely Reduced to tolerance (#{tolerance}) %: #{Math.abs @rateTeamBalanceConfidance teams} , Sums Are #{teams[0].reduce(((a,b) => a + Math.floor(b.score * @preferencequantifier[b.roleID])), 0)}, #{teams[1].reduce(((a,b) => a + Math.floor(b.score * @preferencequantifier[b.roleID])), 0)}"
		teams: teams
		confidence: @percentDiff sums[0], sums[1] #-ve confidance suggests team 1 will win, +ve team 2
	
	###
		Below here are all the functions that take into account the players role preference
		These are slower algorithms
	###
	
	#This variable is used to weight the preferences for each role with index 0 being most preffered
	preferencequantifier: [0.4,0.28,0.16,0.1,0.06]
	#to sort irrespective of role preference set preferencequantifier = [1,1,1,1,1], make sure to reset before sorting by roles.
	resetpreferencequantifier: () -> @preferencequantifier = [0.4,0.28,0.16,0.1,0.06]
	
	#These 2 are convenience functions used throughout the rest of the code
	playerRoleScore: (player, roleIndex=player.roleID) -> Math.floor player.score * @preferencequantifier[roleIndex]
	percentDiff: (a, b) -> (b - a) / Math.max a, b
	playerRolePreferenceIndex: (player, role) ->
		for r of player.preference
			if player.preference[r] is role
				return r
	
	#this function takes in a teamscores[team 0 total score, team 1 total score], teams[[array of team 0 players],[array of team 2 players]], swaps[[team 0 index, team 1 index]]
	#This function modifies the passed in referenced teams to swap the indicated players over and returns the finalteam scores IF the total change will make the team score difference smaller
	multiswapplayers: (teamscores, teams, swaps, debug=false) ->
		#first generate all of the correct data and setup variables
		if debug then console.log swaps
		finalscores = [teamscores[0], teamscores[1]]
		if debug then console.log teams
		currentRoles = for si of swaps
			for sj of swaps[si]
				if debug then console.log "si: #{si}, sj: #{sj}, swap: #{swaps[si][sj]}, teams[sj]: #{teams[sj]}, teams[sj][swaps[si][sj]] #{teams[sj][swaps[si][sj]]}"
				teams[sj][swaps[si][sj]].preference[teams[sj][swaps[si][sj]].roleID]
		#get the targeted preference indices and target role scores
		if debug then console.log currentRoles
		targetRoleIndices = for si of swaps
			for sj of swaps[si]
				@playerRolePreferenceIndex(teams[1-sj][swaps[si][1-sj]],currentRoles[si][sj])
		targetRoleScores = for si of swaps
			for sj of swaps[si]
				@playerRoleScore(teams[1-sj][swaps[si][1-sj]], targetRoleIndices[si][sj])
		
		#NB: This particular version assumes there are no swapping paths/loops in the passed logic all indices in swaps MUST be unique
		if debug then console.log "swap [0][#{swaps[0][0]}] = #{@playerRoleScore teams[0][swaps[0][0]]} -> #{targetRoleScores[0][0]} for [1][#{swaps[0][1]}] = #{@playerRoleScore teams[1][swaps[0][1]]} -> #{targetRoleScores[0][1]} if #{0} < #{-1 * (targetRoleScores.reduce(((a,b) -> a + (b[1] - b[0])), 0)/(teamscores[1] - teamscores[0]))} <= #{0.5}"
		#if we are close to half the difference, sum the differences. The reduce adds together the multiple swaps)
		if 0 < -1 * (targetRoleScores.reduce(((a,b) -> a + (b[1] - b[0])), 0)/(teamscores[1] - teamscores[0])) <= 0.5
			if debug then console.log "swap!"
			# This amends the finalscores based on the swaps; these 1 reductions replace the single version of: targetRoleScores[1] - @playerRoleScore teams[1][team2index]
			finalscores[0] += swaps.reduce(((a,b,i) => a + (targetRoleScores[i][0] - @playerRoleScore teams[0][b[0]])), 0)
			finalscores[1] += swaps.reduce(((a,b,i) => a + (targetRoleScores[i][1] - @playerRoleScore teams[1][b[1]])), 0)
			### We swap the roles on the players; This Replaces:
				teams[0][team1index].roleID = targetRoleIndices[1]
				teams[0][team1index].role = teams[0][team1index].preference[targetRoleIndices[1]]
			###
			for si of swaps
				for sj of swaps[si]
					teams[sj][swaps[si][sj]].roleID = targetRoleIndices[si][1-sj]
					#teams[sj][swaps[si][sj]].role = teams[sj][swaps[si][sj]].preference[targetRoleIndices[si][1-sj]]
			
			#swap players over teams
			for s in swaps
				tempTeam = teams[0][s[0]]
				teams[0][s[0]] = teams[1][s[1]]
				teams[1][s[1]] = tempTeam
		finalscores #don't need to return teams as it's an array reference
	
	
	balance: (players, bestRole=true, tolerance=0.1, debug=false) ->
		#each element in players must have an preference array, a score and a name
		players.sort (a, b) -> b.score - a.score
		teams = [[],[]]
		sums = [0,0]
		teamID = ->
			if teams[0].length is players.length / 2 then 1
			else if teams[1].length is players.length / 2 then 0
			else if sums[0] > sums[1]
				sums[1] += Math.floor p.score * 0.2
				1
			else
				sums[0] += Math.floor p.score * 0.2
				0
		teams[teamID()].push(p) for p in players
		sums = [0,0]
		
		#first run through assigning based on best role
		for ti of teams
			t = teams[ti]
			roleset = (false for i in [0..4])
			if bestRole then t.reverse()
			for p in t
				if not bestRole then p.preference.reverse()
				for ri of p.preference
					r = p.preference[ri]
					if not roleset[r]
						roleset[r] = true
						p.roleID = ri #this means to get the role number we use p.preference[p.roleID]
						#p.role = r
						sums[ti] += @playerRoleScore p
						break
		if Math.abs(@percentDiff sums[0], sums[1]) > tolerance #bad case - means teams are more than tolerance apart
			#now time to try match up the shortfall, negative means that team 0 has higher skill score, positive team 1 has higher skill
			if debug then console.log "******** Do SORT ******** for tolerance #{tolerance}"
			if debug then console.log "---------- Step 1 -  Difference is #{Math.abs @percentDiff sums[0], sums[1]}, sums are: #{sums[0]}, #{sums[1]}"
			(teams[i].sort (a,b) -> a.preference[a.roleID] - b.preference[b.roleID]) for i in [0,1] #sort the players in each team by position, for easier swapping, at this point player at index i is set to position/role i
			sidesSwapped = true
			count = 0
			while sidesSwapped and not (0 < Math.abs(@percentDiff sums[0], sums[1]) <= tolerance) and count < 20
				count++
				sidesSwapped = do =>
					result = false
					for t of teams
						for i of teams[t]
							tempsums = @multiswapplayers sums, teams, [[i, i]]
							#tempsums = swapplayers sums, teams, i, i, tolerance
							if tempsums[0] isnt sums[0] or tempsums[1] isnt sums[1] then result = true
							sums = tempsums
							if 0 < Math.abs(@percentDiff sums[0], sums[1]) <= tolerance then result
					result
			#second reduction if necessary
			if debug then console.log "---------- Step 2 -  Difference is #{Math.abs @percentDiff sums[0], sums[1]}, sums are: #{sums[0]}, #{sums[1]}"
			if Math.abs(@percentDiff sums[0], sums[1]) > tolerance
				do =>
					#in here we attempt to mess up the teams a bit to get some balance if possible
					sidesSwapped = true
					count = 0
					while sidesSwapped and not (0 < Math.abs(@percentDiff sums[0], sums[1]) <= tolerance) and count < 50
						count++
						sidesSwapped = false
						for i of teams[0]
							for j of teams[1]
								#tempsums = swapplayers sums, teams, i, j, tolerance
								tempsums = @multiswapplayers sums, teams, [[i, j]]
								if tempsums[0] isnt sums[0] or tempsums[1] isnt sums[1] then sidesSwapped = true
								sums = tempsums
								if 0 < Math.abs(@percentDiff sums[0], sums[1]) <= tolerance then return
				if Math.abs(@percentDiff sums[0], sums[1]) > tolerance
					#now we are getting into the nasty section - here we have to try swap more than one role pairing at a time...
					if debug then console.log "---------- Step 3: Double swaps -  Difference is #{Math.abs @percentDiff sums[0], sums[1]}, sums are: #{sums[0]}, #{sums[1]}"
					do =>
					#in here we attempt to mess up the teams a bit to get some balance if possible
						sidesSwapped = true
						count = 0
						while sidesSwapped and not (0 < Math.abs(@percentDiff sums[0], sums[1]) <= tolerance) and count < 100
							count++
							sidesSwapped = true
							for i in [0..teams[0].length-2]
								for i2 in [parseInt(i)+1..teams[0].length-1]
									for j in [0..teams[1].length-2]
										for j2 in [parseInt(j)+1..teams[1].length-1]
											tempsums = @multiswapplayers sums, teams, [[i,j],[i2,j2]]
											if tempsums[0] isnt sums[0] or tempsums[1] isnt sums[1] then sidesSwapped = true
											sums = tempsums
											if 0 < Math.abs(@percentDiff sums[0], sums[1]) <= tolerance then return
		if debug then console.log "Completely Reduced to tolerance (#{tolerance}) %: #{Math.abs @rateTeamBalanceConfidance teams} , Sums Are #{teams[0].reduce(((a,b) => a + Math.floor(b.score * @preferencequantifier[b.roleID])), 0)}, #{teams[1].reduce(((a,b) => a + Math.floor(b.score * @preferencequantifier[b.roleID])), 0)}"
		teams: teams
		confidence: @percentDiff sums[0], sums[1] #-ve confidance suggests team 1 will win, +ve team 2
	
	#-ve confidance suggests team 1 (teams[0]) will win, +ve team 2 (teams[1])
	rateTeamBalanceConfidance: (teams) -> @percentDiff teams[0].reduce(((a,b) => a + Math.floor(b.score * @preferencequantifier[b.roleID])), 0), teams[1].reduce(((a,b) => a + Math.floor(b.score * @preferencequantifier[b.roleID])), 0)
		
		
#TESTING STUFF BELOW HERE

###shuffle = (a) ->
    i = a.length
    while --i > 0
        j = ~~(Math.random() * (i + 1))
        t = a[j]
        a[j] = a[i]
        a[i] = t
    a
###
#players = ({score: Math.floor(Math.random() * 10000), name: i, preference: shuffle([0..4])} for i in [1..10])
#resolves in step 1 to correct tolerance 0.1 (0.094)
#players = [ { score: 9200, name: 6, preference: [ 1, 4, 2, 3, 0 ] },  { score: 8670, name: 5, preference: [ 0, 1, 2, 3, 4 ] },  { score: 8362, name: 3, preference: [ 1, 0, 4, 2, 3 ] },  { score: 6820, name: 8, preference: [ 1, 4, 3, 0, 2 ] },  { score: 3168, name: 9, preference: [ 1, 4, 2, 3, 0 ] },  { score: 2608, name: 10, preference: [ 1, 0, 2, 4, 3 ] },  { score: 2489, name: 2, preference: [ 4, 2, 3, 0, 1 ] },  { score: 1471, name: 1, preference: [ 1, 2, 4, 3, 0 ] },  { score: 1089, name: 4, preference: [ 3, 2, 1, 0, 4 ] },  { score: 274, name: 7, preference: [ 4, 1, 2, 3, 0 ] } ]
#fails to resolve in step 1 to correct tolerance 0.1, stops at 0.12, resolves in step 2 in first run - 0.09299
#players = [ { score: 9388, name: 6, preference: [ 4, 1, 0, 2, 3 ] },  { score: 9378, name: 1, preference: [ 3, 4, 2, 1, 0 ] },  { score: 6316, name: 9, preference: [ 2, 4, 1, 0, 3 ] },  { score: 5162, name: 2, preference: [ 1, 0, 4, 3, 2 ] },  { score: 3676, name: 10, preference: [ 1, 3, 4, 2, 0 ] },  { score: 2366, name: 3, preference: [ 4, 2, 0, 3, 1 ] },  { score: 1094, name: 8, preference: [ 3, 2, 4, 1, 0 ] },  { score: 858, name: 4, preference: [ 2, 3, 4, 0, 1 ] },  { score: 254, name: 5, preference: [ 4, 3, 2, 1, 0 ] },  { score: 24, name: 7, preference: [ 1, 4, 3, 0, 2 ] } ]

###
	---------- Step 1 -  Difference is 0.37498771981530604, sums are: 10179, 6362
	---------- Step 2 -  Difference is 0.15986205362109246, sums are: 8989, 7552
	Completely Reduced to tolerance (0.1) %: 0.08712232326195365 , Sums Are 6224, 6818
###
#players = [ { score: 9312, name: 5, preference: [ 4, 3, 0, 2, 1 ] },  { score: 9079, name: 1, preference: [ 1, 4, 3, 2, 0 ] },  { score: 9050, name: 4, preference: [ 3, 4, 0, 2, 1 ] },  { score: 8647, name: 7, preference: [ 1, 0, 2, 4, 3 ] },  { score: 7718, name: 6, preference: [ 2, 1, 0, 3, 4 ] },  { score: 5376, name: 9, preference: [ 1, 3, 4, 0, 2 ] },  { score: 2860, name: 10, preference: [ 1, 4, 3, 0, 2 ] },  { score: 2477, name: 8, preference: [ 1, 3, 0, 2, 4 ] },  { score: 681, name: 2, preference: [ 0, 1, 3, 2, 4 ] },  { score: 637, name: 3, preference: [ 1, 0, 3, 2, 4 ] } ]

#Needs Third Run to solve
#players = [{ score: 7741, name: 10, preference: [ 4, 1, 2, 3, 0 ]},{ score: 806 , name: 6, preference: [ 1, 2, 0, 4, 3 ]},{ score: 1797, name: 5, preference: [ 3, 4, 0, 2, 1 ]},{ score: 3197, name: 4, preference: [ 1, 0, 3, 4, 2 ]},{ score: 9709, name: 3, preference: [ 4, 1, 2, 3, 0 ]},{ score: 4233, name: 2, preference: [ 3, 4, 0, 2, 1 ]},{ score: 8026, name: 9, preference: [ 3, 0, 4, 2, 1 ]},{ score: 6755, name: 1, preference: [ 4, 1, 2, 3, 0 ]},{ score: 5271, name: 8, preference: [ 2, 4, 0, 3, 1 ]},{ score: 6839, name: 7, preference: [ 2, 3, 0, 1, 4 ]}]


###
result = balance players, true, 0.1
for i of result.teams
	console.log "name: #{t.name}, role: #{t.preference[t.roleID]}" for t in result.teams[i]
console.log result.confidence
return
###
###
withinTolerance = 0
outsideTolerance = 0
maxDiff = 0
minDiff = 1
total = 0
bigoutlier = {}
startTime = new Date().getTime()
for i in [1..1000000]
	players = ({score: Math.floor(Math.random() * 10000), name: i, preference: shuffle([0..4])} for i in [1..10])
	result = balance(players)
	maxDiff = Math.max maxDiff, result.confidence
	minDiff = Math.min minDiff, result.confidence
	total += result.confidence
	if result.confidence > 0.1 then outsideTolerance++
	else withinTolerance++
	if result.confidence is maxDiff then bigoutlier = result
totalTime = (new Date().getTime()) - startTime

for el in outliers
	console.log "Confidence of #{el.confidence}"
	console.log el.teams[0]
	console.log el.teams[1]

console.log "Biggest Outlier/Error Confidence of #{bigoutlier.confidence}"
console.log bigoutlier.teams[0]
console.log bigoutlier.teams[1]
console.log "Finished with #{withinTolerance} correct and #{outsideTolerance} wrong in #{totalTime}ms averaging #{totalTime/1000000}ms per execute. Minimum: #{minDiff}, Maximum: #{maxDiff}, average: #{total/1000000}"
###