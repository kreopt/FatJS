all:
	$(COFFEE) -o ../../lib/inSide/core/ -c ./src/core/
	$(MAKE) -C src/widgets all
