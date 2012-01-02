TARGET=target

all: node_modules mangafox-crawler.coffee scraper.coffee

mangafox-crawler.coffee: node_modules
	./node_modules/coffee-script/bin/coffee -o $(TARGET) -c mangafox-crawler.coffee
	
scraper.coffee: node_modules
	./node_modules/coffee-script/bin/coffee -o $(TARGET) -c scraper.coffee

node_modules: clean
	npm install jquery
	npm install underscore
	npm install mkdirp
	npm install coffee-script
	npm install commander
	npm install request
	mkdir $(TARGET)
	cp -R node_modules $(TARGET)/node_modules

clean:
	rm -rf $(TARGET)