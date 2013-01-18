all:
	$(COFFEE) -o ../../lib/jafw/ -c ./src/
	$(MAKE) -C src/widgets all
