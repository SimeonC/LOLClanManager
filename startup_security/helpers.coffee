methods = require 'methods'
path = require 'path'

module.exports = (app, express, __dirname) ->
	privateIoHandlers = []
	publicIoHandlers = []
	
	# shortcuts similar to zappajs - everything else caused complications
	context = 
		include: (p) ->
			sub = if typeof p is 'string' then require path.join(__dirname, p) else p
			sub.include.apply context
			if sub.privateio then privateIoHandlers.push sub.privateio
			if sub.publicio then publicIoHandlers.push sub.publicio
		app: app
		__dirname: __dirname
		configure: (p) ->
			if typeof p is 'function' then app.configure p
			else app.configure k, v for k, v of p
			return
		express: express
	
	#setup the verb handlers
	for verb in ['set', 'get', 'use', 'post', 'put', 'all']
		context[verb] = ((verb) -> -> app[verb].apply app, arguments)(verb)
	
	# return these values
	privateIoHandlers: privateIoHandlers
	publicIoHandlers: publicIoHandlers
	context: context