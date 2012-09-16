all:
	node build.js
	coffee -o ./lib/js/ -c ./src/coffee
	cp -r ./src/lib/* ./lib/js/lib