PATH := ./node_modules/.bin:${PATH}

.PHONY : init clean-docs clean build test dist publish

all: build

init:
	npm install

clean:
	rm -rf dist/

build:
	coffee -o dist/ -c src/
	sed -i '1i#!/usr/bin/env node' dist/main.js

dist: clean init build
	npm pack

publish: dist
	npm publish
