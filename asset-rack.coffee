@include = ->
	rack = require 'asset-rack'
	
	@assets = new rack.Rack [
		new rack.DynamicAssets
			type: rack.StylusAsset
			urlPrefix: '/assets/css'
			dirname: __dirname + '/assets/stylus'
			filter: '.styl'
		new rack.SnocketsAsset
			url: '/assets/js/app.js'
			filename: __dirname + '/assets/coffeescript/app.coffee'
		new rack.SnocketsAsset
			url: '/assets/js/new.js'
			filename: __dirname + '/assets/coffeescript/new.coffee'
		new rack.SnocketsAsset
			url: '/assets/js/multiteam.js'
			filename: __dirname + '/assets/coffeescript/multiteam.coffee'
		new rack.StaticAssets
			urlPrefix: '/assets/js'
			dirname: __dirname + '/assets/javascript'
	]