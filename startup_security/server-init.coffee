passport = require 'passport'
Auth0Strategy = require 'passport-auth0'
security = require('./security')

strategy = new Auth0Strategy 
	domain:       security.auth0.domain
	clientID:     security.auth0.clientID
	clientSecret: security.auth0.clientSecret
	callbackURL:  '/callback'
, (accessToken, refreshToken, profile, done) ->
	console.log "Hit Auth0 strategy"
	done null, profile

passport.use strategy

# This is not a best practice, but we want to keep things simple for now
passport.serializeUser (user, done) -> done null, user

passport.deserializeUser (user, done) -> done null, user

@include = ->
	#@set 'env', 'development'
	helmet = require 'helmet'
	@include 'asset-rack'
	
	@use (req, res, next) -> 
		res.locals.helpers = require './../views/layout-helpers'
		next()
	
	@configure =>
		@use @express.logger 'dev'
		@set 'views', "#{@__dirname}/views"
		@app.engine 'jade', require('consolidate').jade
		@set 'view engine', 'jade'
		
		@use helmet.xframe(), helmet.iexss(), helmet.contentTypeOptions(), helmet.cacheControl()
		@use @express.json(), @express.urlencoded()
		@use @express.methodOverride()
		@use @express.cookieParser()
		@use @express.session
			secret: security.cookieSecret
			#cookie:
				#httpOnly: true
				# secure: true # for HTTPS only
		@use passport.initialize()
		@use passport.session()
		@use require('express-validator')()
	
	#@all '/api/*', passport.authenticate 'auth0'
	
	@auth = passport.authenticate 'auth0'
	# Auth0 callback handler
	@get '/callback', passport.authenticate('auth0',
		failureRedirect: '/login'
	), (req, res) ->
		if not req.user then throw new Error 'user null'
		console.log "hit callback"
		console.log req.user
		if req.user._json.appid?
			req.session.dbconn = require('./../startup_security/nano').nano req.user._json.user_id, req.user._json.dbpass
			res.redirect "/#{req.user._json.appid}/manage"
		else res.redirect "/first-login"
	
	@get '/logout', (req, res) ->
		req.logout()
		delete req.session
		res.redirect "/"