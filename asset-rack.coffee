@include = ->
	ConnectMincer = require 'connect-mincer'

	connectMincer = new ConnectMincer
		mincer: require "mincer"
		root: __dirname
		production: process.env.NODE_ENV is 'production'
		mountPoint: '/assets'
		manifestFile: __dirname + '/public/assets/manifest.json'
		paths: [
			'assets/coffeescript',
			'assets/javascript',
			'assets/stylus',
			'bower_components/angular-strap/dist',
			'bower_components/angular-motion/dist',
			'assets/images'
		]
	@use connectMincer.assets()
	if process.env.NODE_ENV isnt 'production' then @app.use '/assets', connectMincer.createServer()