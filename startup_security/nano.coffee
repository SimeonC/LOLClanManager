security = require './security'
_nano = require 'nano'
prefix = if security.couchdb.ssl is true then "https" else "http"

module.exports = exports =
	admin_nano: (cb) ->
		nano = _nano "#{prefix}://#{security.couchdb.url}"
		nano.auth security.couchdb.admin_user.username, security.couchdb.admin_user.password, (err, response, headers) ->
			cb _nano
				url: "#{prefix}://#{security.couchdb.url}"
				cookie: headers['set-cookie']
	# If username and password is passed, use them to login. Else login as anon user
	nano: (username, password, cb) -> if username? and password?
		db = _nano "#{prefix}://#{security.couchdb.url}"
		db.auth username, password, (err, response, headers) ->
			cb _nano
				url: "#{prefix}://#{security.couchdb.url}"
				cookie: headers['set-cookie']
	else _nano "#{prefix}://#{security.couchdb.url}"