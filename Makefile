TARGET=target

all: node_modules mangafox-crawler.js 

mangafox-crawler.js:
	coffee -o $(TARGET) -c mangafox-crawler.coffee

node_modules: target
	cp -R node_modules $(TARGET)

target: clean
	mkdir -p $(TARGET)/node_modules

clean:
	rm -rf $(TARGET)