security = require './security'
api = require 'leagueapi'

module.exports = exports = (server_key="na") ->
	api.init security.lolapikey, server_key
	return api