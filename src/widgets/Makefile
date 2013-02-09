all:
	@for d in ./*; \
	do                               \
		if [ -d $$d ]; then\
		$(MAKE) -C $$d all;       \
		fi;\
	done;
clean:
	@for d in ./*; \
	do                               \
		if [ -d $$d ]; then\
		$(MAKE) -C $$d clean;       \
		fi;\
	done;
