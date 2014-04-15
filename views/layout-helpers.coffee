exports = module.exports =
	outputLeaderStar: (playerIdVar, teamIdVar, outlineStar=false) ->
		"""
		<span class="leader-star-wrap">
		""" +
		(if teamIdVar? then """
		<i
			class="fa fa-star"
			ng-if="data.players[#{playerIdVar}].leader || #{playerIdVar} == session.teams[#{teamIdVar}].leader"
			style="margin-right: 6px;"
			ng-class="{
				'fa-star-o': data.players[#{playerIdVar}].leader && (session.teams[#{teamIdVar}].players.indexOf(#{playerIdVar}) == -1 || (session.teams[#{teamIdVar}].leader && '' != session.teams[#{teamIdVar}].leader && #{playerIdVar} != session.teams[#{teamIdVar}].leader))}"></i>
		"""
		else """
		<i class="fa fa-star#{if outlineStar then '-o' else ''}" ng-if="data.players[#{playerIdVar}].leader" style="margin-right: 6px;"></i>
		""") + """
		</span>
		"""
	outputPlayer: (playerIdVar, teamIdVar, outlineStar=false, showScore=false) ->
		"""
			#{@outputLeaderStar playerIdVar, teamIdVar, outlineStar}
			{{data.players[#{playerIdVar}].name}}#{if showScore then " ({{data.players[#{playerIdVar}].scores.aggregate}})" else ''}
			<i class="fa fa-spinner fa-spin pull-right" ng-show="data.players[#{playerIdVar}].updating"></i>
			<i class="fa fa-exclamation-triangle pull-right" ng-show="!data.players[#{playerIdVar}].updating && data.players[#{playerIdVar}].updatingerror && data.players[#{playerIdVar}].updatingerror != ''"></i>
		"""
	baseAppIdTag: (appId) -> if appId? and appId.length isnt 0 then "<base href='/#{appId}/'/>" else "<base href='/'/>"