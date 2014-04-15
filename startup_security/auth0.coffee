security = require './security'

Auth0 = require 'auth0'


module.exports = exports = new Auth0
	domain:       security.auth0.domain
	clientID:     security.auth0.clientID
	clientSecret: security.auth0.clientSecret