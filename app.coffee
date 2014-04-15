fs = require "fs"
http = require 'http'
https = require 'https'
express = require "express"
socketio = require('socket.io')

###
privateKey  = fs.readFileSync('sslcert/server.key', 'utf8');
certificate = fs.readFileSync('sslcert/server.crt', 'utf8');
credentials = 
	key: privateKey
	cert: certificate
###

app = module.exports = express()

httpServer = http.createServer app
# httpsServer = https.createServer(credentials, app);

helpers = require('./startup_security/helpers') app, express, __dirname
helpers.context.io = io = socketio.listen httpServer

joinRoom = (data) ->
	@leave(@client.room) if @client.room
	@client.room = data.room
	@join @client.room

helpers.context.publicio = io.of '/public'
	.on 'connection', (socket) ->
		socket.client = {}
		socket.context = helpers.context
		socket.on 'joinroom', joinRoom
		handler.apply socket for handler in helpers.publicIoHandlers
		return
helpers.context.privateio = io.of '/private'
	.on 'connection', (socket) ->
		socket.client = {}
		socket.context = helpers.context
		socket.on 'joinroom', joinRoom
		handler.apply socket for handler in helpers.privateIoHandlers
		return

helpers.context.include './startup_security/server-init'
helpers.context.include './routes'

httpServer.listen 3000
# httpsServer.listen 3443

console.log "Server Running on port 3000 via ExpressJS"
console.log "Serving Sockets Via Socket.io"
console.log "Authentication Via Passport.js and Auth0"
console.log "Data via couchdb"