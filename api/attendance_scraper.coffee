request = require 'request'
tough = require 'tough-cookie'
cookieJar = request.jar()
request.defaults
	jar: cookieJar
cheerio = require 'cheerio'

exports = module.exports =
	getAttendance: (eventID, username, password, cb) ->
		request
				uri: "https://taw.net/themes/taw/common/login.aspx?ReturnUrl=%2fevent%2f#{eventID}.aspx"
				method: 'post'
				form:
					ctl00$bcr$ctl03$ctl07$username: username
					ctl00$bcr$ctl03$ctl07$password: password
					__EVENTTARGET: ''
					__EVENTARGUMENT: ''
					__VIEWSTATE: '/wEPDwUKMTE5OTA4Nzc3OWQYAQUeX19Db250cm9sc1JlcXVpcmVQb3N0QmFja0tleV9fFgQFJmN0bDAwJGJjciRjdGwwMyRjdGwwNyRzdGVhbUxvZ2luQnV0dG9uBR5jdGwwMCRiY3IkY3RsMDMkY3RsMDckdXNlcm5hbWUFHmN0bDAwJGJjciRjdGwwMyRjdGwwNyRwYXNzd29yZAUfY3RsMDAkYmNyJGN0bDAzJGN0bDA3JGF1dG9Mb2dpbsgpoPyuibLcFEi/x4qBNlDptUIm'
					ctl00$bcr$ctl03$ctl07$autoLogin: 'off'
					ctl00$bcr$ctl03$ctl07$loginButton: 'Sign in È'
				jar: cookieJar
			, (err,resp,body) =>
				$ = cheerio.load body
				if $('div.CommonContentBox h2.CommonContentBoxHeader').text() is "Invalid User Credentials"
					request
						uri: 'http://taw.net/logout.aspx'
						jar: cookieJar
					return cb true,
						name: "Login Error"
						message: "Invalid Login Username / Password"
				attending = []
				rows = $('div#ctl00_ctl00_bcr_bcr_UpdatePanel table').last().find('tr')
				if rows.length is 0
					request
						uri: 'http://taw.net/logout.aspx'
						jar: cookieJar
					return cb true,
						name: "Event Error"
						message: "Invalid Event ID"
				for i in [1...rows.length-1]
					row = rows.eq(i)
					if row.find('td:nth-child(2)').text().trim() is 'attended' then attending.push row.find('td:first-child a').text().trim()
				request
					uri: 'http://taw.net/logout.aspx'
					jar: cookieJar
				cb false, attending