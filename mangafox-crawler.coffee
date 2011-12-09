url = require 'url'
http = require 'http'
fs = require 'fs'
$ = require 'jquery'
_ = require 'underscore'

console.log 'started'
crawlQueue = ['http://www.mangafox.com/manga/my_little_sister_can_t_be_this_cute/v04/c026/']
downloadQueue = []
	
download = () ->
	return if downloadQueue.length is 0
	
	downloadInfo = downloadQueue.pop()
	
	pageUrl = downloadInfo.pageUrl
	imageUrl = downloadInfo.imageUrl
	
	pathArray = _.rest(pageUrl.split('/'), 4)
	directory = url.resolve(pathArray.join('/'), './')
	pathArray = directory.split('/')
	filename = directory + _.last(imageUrl.split('/'))
	console.log 'page: ' + pageUrl + ' image: ' + imageUrl + ' filename: ' + filename
	
	currentDir = ''
	for path in pathArray
		if path is ''
			break
		
		currentDir += (path + '/')
		try
			fs.mkdirSync(currentDir)
		catch error
			#do nothing
	
	currentDir = null
	
	parsedUrl = url.parse imageUrl
	options = {
		"host": parsedUrl.hostname,
		"port": 80,
		"path": parsedUrl.pathname
	}
	
	#clean up
	parsedUrl = null
	pathArray = null
	directory = null
	
	file = fs.createWriteStream (filename), {"flags":'w'}
	request = http.get options, (response) -> 
		response.on 'data', (chunk) ->
			file.write chunk
			
		response.on 'end', () ->
			console.log 'downloaded: ' + filename
			file.end()
			file.destroySoon()
			
	request.end()
	
scrape = () ->
	return if crawlQueue.length is 0
	
	hostUrl = crawlQueue.pop()
	host = url.parse hostUrl
	
	options = {
		"host": host.hostname,
		"port": 80,
		"path": host.pathname,
		"method": 'GET'
	}
	
	host = null
	
	request = http.request options, (response) ->
		html = ''
		response.setEncoding 'utf8'
	
		response.on 'data', (chunk) ->
			html += chunk
	
		response.on 'end', () ->
			$html = $(html)
			$image = $html.find '#image'
			
			#page after final chapter
			if $image.length is 0
				quit()
				return
			
			imageUrl = $image.attr('src')
			downloadQueue.push {"pageUrl": hostUrl, "imageUrl": imageUrl}
			
			href = $image.parent('a').attr('href')
			
			if !href
				quit()
				return
			
			#last page of chapter
			if href is 'javascript:void(0);'
				href = $html.find('span:contains("Next Chapter:") + a').attr('href')
			
			nextUrl = url.resolve hostUrl, href
			
			crawlQueue.push nextUrl
		
	request.end()
	
quit = () ->
	setInterval (() ->
		console.log 'waiting to finish'
		if crawlQueue.length is 0 and downloadQueue.length is 0
			console.log 'finished'
			process.exit(0)
	), 1000


setInterval scrape, 50 
setInterval download, 50