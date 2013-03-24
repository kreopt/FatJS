all:
	$(COFFEE) -o ../../lib/inSide/core/ -c ./src/core/
	$(COFFEE) -o ../../lib/inSide/server/ -c ./src/server/
	$(MAKE) -C src/widgets all
