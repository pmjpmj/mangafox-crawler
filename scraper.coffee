url = require 'url'
fs = require 'fs'
$ = require 'jquery'
_ = require 'underscore'
request = require 'request'
cp = require 'child_process'

inProgress = false

padStr = (string, size, padding) ->
    if typeof string is 'number'
        _size = size
        size = string
        string = _size
    string = string.toString()
    pad = ''
    size = size - string.length
    for i in [0 ... size]
        pad += padding
    if _size
    then pad + string
    else string + pad
    
quit = () ->
	setInterval (() ->
		if not inProgress
			process.exit(0)
		), 1000

download = (pageUrl, imageUrl, counter, target) ->	
	inProgress = true
	directory = _.first(_.rest(pageUrl.split('/'), 4))
	if target
		if target.indexOf('/') is -1
			directory = '/' + directory
		
		directory = target + directory
	
	info =
		pageUrl: pageUrl
		imageUrl: imageUrl
		filename: directory + '/' + padStr(8, counter.toString(), 0) + '.' + _.last(imageUrl.split('.'))
			
	process.nextTick () ->
		request(info.imageUrl).pipe(fs.createWriteStream(info.filename).on(
			'close',
			() ->
				console.log info.pageUrl + ' downloaded as ' + info.filename
				inProgress = false
		))

scrape = (pageUrl, counter, target) ->
	request pageUrl, (error, response, body) ->
		if not error and response.statusCode is 200
			$image = $(body).find('#image')
			
			#page after final chapter
			if $image.length is 0
				quit()
				return
			
			process.nextTick () -> download pageUrl, $image.attr('src'), counter, target
				
			href = $image.parent('a').attr('href')
			
			if !href
				quit()
				return
			
			#last page of chapter
			if href is 'javascript:void(0);'
				href = $(body).find('span:contains("Next Chapter:") + a').attr('href')
			
			nextUrl = url.resolve pageUrl, href
			counter++
			
			child = cp.fork(__dirname + '/scraper.js')
			child.send {url: nextUrl, counter: counter, target: target}
			
			quit()

process.on 'message', (message) ->
	scrape message.url, message.counter, message.target