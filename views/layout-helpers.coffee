exports = module.exports =
	outputLeaderStar: (playerIdVar, teamIdVar, outlineStar=false, textYellow=true) ->
		"""
		<span class="leader-star-wrap">
		""" +
		(if teamIdVar? then """
		<i
			class="fa fa-star"
			ng-if="data.players[#{playerIdVar}].leader || #{playerIdVar} == session.teams[#{teamIdVar}].leader"
			style="margin-right: 6px;"
			ng-class="{
				'text-yellow': !session.teams[#{teamIdVar}].leader || session.teams[#{teamIdVar}].leader == #{playerIdVar},
				'fa-star-o': data.players[#{playerIdVar}].leader && session.teams[#{teamIdVar}].leader && '' != session.teams[#{teamIdVar}].leader && #{playerIdVar} != session.teams[#{teamIdVar}].leader}"></i>
		"""
		else """
		<i class="fa fa-star#{if outlineStar then '-o' else ''} #{if textYellow then 'text-yellow' else ''}" ng-if="data.players[#{playerIdVar}].leader" style="margin-right: 6px;"></i>
		""") + """
		</span>
		"""