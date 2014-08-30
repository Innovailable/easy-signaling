PATH := ./node_modules/.bin:${PATH}

.PHONY : init clean-docs clean build test dist publish

init:
	npm install

clean:
	rm -rf dist/

build:
	coffee -o dist/ -c src/

dist: clean init build
	npm pack

publish: dist
	npm publish
