@include = ->
	
	@get '/login', (req, res) -> res.render 'login.jade'
	@get '/first-login', @auth, (req, res) -> res.render 'first-login.jade'
	
	@get '/partials/dashboard', (req, res) -> res.render 'partials/dashboard.jade'
	@get '/partials/loading', (req, res) -> res.render 'partials/loading.jade'
	@get '/partials/player', (req, res) -> res.render 'partials/player.jade'
	@get '/partials/session', (req, res) -> res.render 'partials/session.jade'
	@get '/partials/team', (req, res) -> res.render 'partials/team.jade'
	@get '/partials/event', (req, res) -> res.render 'partials/event.jade'
	@get '/partials/newevent', (req, res) -> res.render 'partials/newevent.jade'
	@get '/partials/settings', (req, res) -> res.render 'partials/settings.jade'
	
	@get '/', (req, res) -> res.render 'home.jade'
	@get '/optimiser', (req, res) -> res.render 'balancer.jade'
	@get '/:appid/manage*', @auth, (req, res) -> res.render 'app.jade',
		appId: req.params.appid
	
	#must be laste as it's the most generic
	@get '/:appid/*', (req, res) -> res.render 'public_event.jade',
		appId: req.params.appid