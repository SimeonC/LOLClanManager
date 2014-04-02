fs = require 'fs'

require('zappajs') ->
	@on "error": ->
		console.log @data
		console.log @data.stack
	@include './startup_security/server-init'
	@include './routes'