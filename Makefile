PATH := ./node_modules/.bin:${PATH}

.PHONY : init clean-docs clean build test dist publish

all: build

init: node_modules

node_modules: package.json
	npm install
	touch node_modules

clean:
	rm -rf dist/

doc: init
	node_modules/.bin/yuidoc --syntaxtype coffee -e .coffee -o doc src

build: init
	node_modules/.bin/coffee -o dist/ -c src/
	sed -i '1i#!/usr/bin/env node' dist/main.js

dist: build
	npm pack

publish: dist
	npm publish

.PHONY: doc build dist publich clean init all
