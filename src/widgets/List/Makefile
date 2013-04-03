
LIB_PATH=../../../../../lib/inSide/widgets/
include ../local.mk
include application.mk
all: $(JS) $(CSS) $(HTML)
clean:
	rm -f $(JS) $(CSS) $(HTML)
$(LIB_PATH)$(APP_NAME)/%.js: %.coffee
	$(COFFEE) -o `dirname $@` -c $<
$(LIB_PATH)$(APP_NAME)/%.css: %.less
	$(LESS) -x $< > $@
$(LIB_PATH)$(APP_NAME)/%.jade: %.jade
	$(CP) $< $@
