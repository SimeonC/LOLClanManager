@include = ->
	
	@app.locals.helpers = require './layout-helpers'
	
	@get '/optimiser': -> @render 'balancer.jade'
	renderManagerApp = -> @render 'app.jade'
	@get '/manager': renderManagerApp
	@get '/dashboard': renderManagerApp
	@get '/player/*': renderManagerApp
	@get '/session/*': renderManagerApp
	@get '/team/*': renderManagerApp
	@get '/newplayer': renderManagerApp
	@get '/newsession': renderManagerApp
	@get '/newteam': renderManagerApp
	@get '/newevent/*': renderManagerApp
	@get '/event/*': renderManagerApp
	@get '/public/*': -> @render 'public_event.jade'
	
	@get '/partials/dashboard': -> @render 'partials/dashboard.jade'
	@get '/partials/loading': -> @render 'partials/loading.jade'
	@get '/partials/player': -> @render 'partials/player.jade'
	@get '/partials/session': -> @render 'partials/session.jade'
	@get '/partials/team': -> @render 'partials/team.jade'
	@get '/partials/event': -> @render 'partials/event.jade'
	@get '/partials/newevent': -> @render 'partials/newevent.jade'