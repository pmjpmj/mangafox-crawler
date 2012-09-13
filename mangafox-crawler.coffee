commander = require 'commander'
cp = require 'child_process'
_ = require 'underscore'
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

url = commander.args[0]
counter = if commander.startno then (Number) commander.startno else 1
target = commander.target

directory = _.first(_.rest(url.split('/'), 4))
if target
	if target.indexOf('/') is -1
		directory = '/' + directory
	
	directory = target + directory
	
mkdirp.sync directory, 0o0755

createWorker = (args) ->
	child = cp.fork(__dirname + '/scraper.js')
	child.on 'message', (message) ->
		child = createWorker message
		
	child.send {url: args.url, counter: args.counter, target: args.target}
	return child

# send first url to child process
createWorker {url: url, counter: counter, target: target}

console.log 'started'
