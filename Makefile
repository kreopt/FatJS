all:
	$(COFFEE) -o ../../lib/jafw/core -c ./src/core
	$(MAKE) -C src/widgets all
