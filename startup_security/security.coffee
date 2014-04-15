fs = require 'fs'

fs.readFileSync __dirname + '/startup_security/security.json', (err, data) ->
	if err then console.log "Error: #{err}"
	else
		exports = module.exports = JSON.parse data