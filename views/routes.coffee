@include = ->
	
	@get '/optimiser': -> @render 'index.jade'
	@get '/': -> @render 'multiteam.jade',
		globals: ['assets']