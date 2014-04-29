passport = require 'passport'
Auth0Strategy = require 'passport-auth0'
security = require('./security')

strategy = new Auth0Strategy 
	domain:       security.auth0.domain
	clientID:     security.auth0.clientID
	clientSecret: security.auth0.clientSecret
	callbackURL:  '/callback'
, (accessToken, refreshToken, profile, done) -> done null, profile

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
		# catch errors in general
		@use (err, req, res, next) ->
			console.log "catch error #{err.status}"
			if err.status is 401 or err.status is 403 then res.render '/login',
				error: "Please login before you can access this page."
			else if err.status is 404 then res.render '/404'
			else
				res.status err.status or 500
				res.render 'error',
					error: err
	
	@auth = (req, res, next) -> if req.isAuthenticated() then next() else res.redirect 307, '/login'
	@user_db = (req, cb) -> require('./../startup_security/nano').nano req.user._json.user_id, req.user._json.dbpass, (nano_conn) -> cb nano_conn.use req.user._json.appid
	@all '/api/*', @auth
	
	# Auth0 callback handler
	@get '/callback', passport.authenticate('auth0',
		failureRedirect: '/login'
	), (req, res) ->
		if not req.user then throw new Error 'user null'
		if req.user._json.appid? then res.redirect "/#{req.user._json.appid}/manage"
		else res.redirect "/first-login"
	
	# warning this would log you out of facebook if you logged in via the facebook button - don't use this in live!
	@get '/logout', (req, res) ->
		req.logout()
		delete req.session
		delete req.user
		res.redirect "https://simeonc.auth0.com/logout?returnTo=http://tawmanager.localhost:3000/"