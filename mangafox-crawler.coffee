commander = require 'commander'
cp = require 'child_process'

commander
	.version('0.0.1')
	.usage('[options] <url>')
	.option('-t, --target <path>', 'target path')
	.option('-n, --startno <no>', 'image file start number')
	.parse(process.argv)

if commander.args.length is 0
	console.log 'url must be provided'
	process.exit(1)

counter = if commander.startno then commander.startno else 1
target = commander.target

process.on 'message', (message) ->
	console.log 'parent'
	console.log message
	newChild = cp.fork(__dirname + '/scraper.js')
	newChild.send {url: message.url, counter: message.counter, target: target}

child = cp.fork(__dirname + '/scraper.js')
child.send {url: commander.args[0], counter: counter, target: target}

console.log 'started'

	