url = require 'url'
http = require 'http'
fs = require 'fs'
$ = require 'jquery'
_ = require 'underscore'
commander = require 'commander'
mkdirp = require 'mkdirp'

commander
	.version('0.0.1')
	.usage('[options] <url>')
	.option('-t, --target <path>', 'target path')
	.option('-n, --startno <no>', 'image file start number')
	.parse(process.argv)

if commander.args.length is 0
	console.log 'url must be provided'
	process.exit(1)

console.log 'started'
crawlQueue = [commander.args[0]]
downloadQueue = []
counter = if commander.startno then commander.startno else 1

download = () ->
	return if downloadQueue.length is 0
	
	downloadInfo = downloadQueue.pop()
	
	pageUrl = downloadInfo.pageUrl
	imageUrl = downloadInfo.imageUrl
	
	directory = _.first(_.rest(pageUrl.split('/'), 4))

	if commander.target
		if commander.target.indexOf('/') is -1
			directory = '/' + directory
		
		directory = commander.target + directory
		
	filename = directory + '/' + (counter++) + '.' + _.last(imageUrl.split('.'))
	
	console.log 'page: ' + pageUrl + ' image: ' + imageUrl + ' filename: ' + filename
	
	mkdirp.sync directory, 0755
	
	parsedUrl = url.parse imageUrl
	options =
		host: parsedUrl.hostname
		port: 80
		path: parsedUrl.pathname
	
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
	
	options =
		host: host.hostname
		port: 80
		path: host.pathname
		method: 'GET'
	
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