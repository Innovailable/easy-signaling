PATH := ./node_modules/.bin:${PATH}

.PHONY : init clean-docs clean build test dist publish

all: build

init: node_modules

clean:
	rm -rf dist/

node_modules: package.json
	npm install

build: node_modules
	npm install
	node_modules/.bin/coffee -o dist/ -c src/
	sed -i '1i#!/usr/bin/env node' dist/main.js

dist: clean init build
	npm pack

publish: dist
	npm publish
