security = require './security'
_nano = require 'nano'
prefix = if security.couchdb.ssl is true then "https" else "http"
nano = _nano "#{prefix}://#{security.couchdb.admin_user.username}:#{security.couchdb.admin_user.password}@#{security.couchdb.url}"


module.exports = exports =
	admin_nano: nano
	# If username and password is passed, use them to login. Else login as anon user
	nano: (username, password) -> if username? and password? then _nano "#{prefix}://#{username}:#{password}@#{security.couchdb.url}" else _nano "#{prefix}://#{security.couchdb.url}"