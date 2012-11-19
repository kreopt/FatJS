include ./application.mk

LIB_PATH=../../../../../lib/apps/
all: $(JS) $(CSS) $(HTML)
%.js: %.coffee
	$(COFFEE) -o $(LIB_PATH)$(APP_NAME) -c $<
%.css: %.less
	$(LESS) -x $< > $(LIB_PATH)$(APP_NAME)/`echo "$@" | cut -d'/' -f2`
%.tpl: %.html
	$(CP) $< $(LIB_PATH)$(APP_NAME)/`echo "$@" | cut -d'/' -f2`
