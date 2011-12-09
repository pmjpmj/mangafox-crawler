url = require 'url'
http = require 'http'
fs = require 'fs'
$ = require 'jquery'
_ = require 'underscore'

console.log 'start'
downloadCallCount = 0
	
download = (pageUrl, imageUrl) ->
	pathArray = _.rest(pageUrl.split('/'), 4)
	directory = url.resolve(pathArray.join('/'), '.') + "/"
	filename = directory + _.last(imageUrl.split('/'))
	console.log 'image: ' + imageUrl + ' filename: ' + filename
	
	currentDir = ''
	for path in pathArray
		currentDir += (path + '/')
		console.log currentDir
		try
			fs.mkdirSync(currentDir)
		catch error
			console.log error
			#do nothing
		
	file = fs.createWriteStream (filename), {"flags":'w'}
	
	parsedUrl = url.parse imageUrl
	options = {
		"host": parsedUrl.hostname,
		"port": 80,
		"path": parsedUrl.pathname
	}
	
	request = http.get options, (response) -> 
		response.on 'data', (chunk) ->
			file.write chunk
			
		response.on 'end', () ->
			console.log 'downloaded: ' + filename
			file.end()
			downloadCallCount--
	
	downloadCallCount++
	request.end()
	
scrape = (hostUrl) ->
	
	host = url.parse hostUrl
	nextUrl = host.pathname
	
	options = {
		"host": host.hostname,
		"port": 80,
		"path": host.pathname,
		"method": 'GET',
		"url": hostUrl
	}
	
	request = http.request options, (response) ->
		html = ''
		response.setEncoding 'utf8'
	
		response.on 'data', (chunk) ->
			html += chunk
	
		response.on 'end', () ->
			$html = $(html)
			image = $html.find '#image'
			
			#page after final chapter
			if image.length is 0
				quit()
				return
			
			imageUrl = image.attr('src')
			download(options.url, imageUrl)
			
			href = image.parent('a').attr('href')
			
			#last page of chapter
			if href is 'javascript:void(0);'
				href = $html.find('span:contains("Next Chapter:") + a').attr('href')
			
			nextUrl = url.resolve options.url, href		
			console.log 'next url: ' + nextUrl
			
			#get next page - avoid stack overflow
			process.nextTick () -> scrape(nextUrl)
		
	request.end()
	
quit = () ->
	setInterval (() ->
		console.log 'waiting to finish with ' + downloadCallCount + ' calls remaining'
		if downloadCallCount is 0
			console.log 'finished'
			process.exit(0)
	), 1000

scrape('http://www.mangafox.com/manga/maken_ki/v01/c001/')