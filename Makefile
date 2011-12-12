TARGET=target

all: node_modules mangafox-crawler.coffee

mangafox-crawler.coffee: target scraper.coffee
	coffee -o $(TARGET) -c mangafox-crawler.coffee
	
scraper.coffee: target
	coffee -o $(TARGET) -c scraper.coffee

node_modules: target
	cp -R node_modules $(TARGET)

target: clean
	mkdir -p $(TARGET)/node_modules

clean:
	rm -rf $(TARGET)