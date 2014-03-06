@include = ->
	helmet = require 'helmet'
	@include 'asset-rack'
	
	@configure =>
		@use @assets
		@set 'view options':
			layout: false
		@app.engine 'jade', require('consolidate').jade
		@set 'view engine': 'jade'
		@use helmet.xframe(), helmet.iexss(), helmet.contentTypeOptions(), helmet.cacheControl()
		@use @express.json(), @express.urlencoded()
		@use 'methodOverride'
		@use @express.cookieParser()
		###@use @express.session
			secret: 'bigkeyhere'
			cookie:
				httpOnly: true
				secure: true
		@use @express.csrf()
		@app.use (req, res, next) ->
			res.locals.csrftoxen = req.session._csrf
			next()###
		@use 'static'
		@use require('express-validator')()