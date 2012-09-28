CMP 'jafw.gui.SideMenu',
    __forms:['@menu']
    __css:['gui/SideMenu']
    _init:(oConfig)->
        @container=oConfig.container
        @launcher=new JAFW.Launcher(oConfig.contentContainer.id,false)
        @menuId=oConfig.id
        addClass(@container,'JAFW_SideMenu')
        @reload(oConfig.items)
    setItemEvent:(event,handler)->
        addEventBySelector "##{@menuId} li",event,handler
    reload:(aItems)->
        @RENDER '@menu',@container,{menuId:@menuId,items:aItems}
        app=@
        if aItems.length
            first=$s('li',$s("##{app.menuId}"))
            addUniqueClass(first,'Selected',$s("##{app.menuId}"))
            app.launcher.run(first.dataset['page'])
        addEventBySelector "##{@menuId} li",'click',->
            addUniqueClass(@,'Selected',$s("##{app.menuId}"))
            app.launcher.run(@dataset['page'])