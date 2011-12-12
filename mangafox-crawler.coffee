url = require 'url'
fs = require 'fs'
$ = require 'jquery'
_ = require 'underscore'
commander = require 'commander'
mkdirp = require 'mkdirp'
request = require 'request'

commander
	.version('0.0.1')
	.usage('[options] <url>')
	.option('-t, --target <path>', 'target path')
	.option('-n, --startno <no>', 'image file start number')
	.parse(process.argv)

if commander.args.length is 0
	console.log 'url must be provided'
	process.exit(1)

inProgress = false
counter = if commander.startno then commander.startno else 1

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
		console.log 'waiting to finish'
		if not inProgress
			console.log 'finished'
			process.exit(0)
	), 1000

download = (pageUrl, imageUrl) ->	
	directory = _.first(_.rest(pageUrl.split('/'), 4))
	if commander.target
		if commander.target.indexOf('/') is -1
			directory = '/' + directory
		
		directory = commander.target + directory
		
	mkdirp.sync directory, 0755
	
	info =
		pageUrl: pageUrl
		imageUrl: imageUrl
		filename: directory + '/' + padStr(8, counter.toString(), 0) + '.' + _.last(imageUrl.split('.'))
			
	process.nextTick () ->
		inProgress = true
		request(info.imageUrl).pipe(fs.createWriteStream(info.filename).on(
			'close',
			() ->
				console.log info.pageUrl + ' downloaded as ' + info.filename
				inProgress = false
		))
	
	counter++
	return info

scrape = (pageUrl) ->
	request pageUrl, (error, response, body) ->
		if not error and response.statusCode is 200
			$image = $(body).find('#image')
			
			#page after final chapter
			if $image.length is 0
				quit()
				return
			
			process.nextTick () -> download pageUrl, $image.attr('src')
				
			href = $image.parent('a').attr('href')
			
			if !href
				quit()
				return
			
			#last page of chapter
			if href is 'javascript:void(0);'
				href = $(body).find('span:contains("Next Chapter:") + a').attr('href')
			
			nextUrl = url.resolve pageUrl, href
			
			process.nextTick () -> scrape nextUrl
			
#started
scrape commander.args[0]


	