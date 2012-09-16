CMP 'jafw.gui.SideMenu',
    __forms:['@menu']
    __css:['gui/SideMenu']
    _init:(oConfig)->
        @container=oConfig.container
        @launcher=new JAFW.Launcher(oConfig.contentContainer.id,false)
        addClass(@container,'JAFW_SideMenu')
        @RENDER '@menu',@container,{menuId:oConfig.id,items:oConfig.items}
        app=@
        addEventBySelector "##{oConfig.id} li",'click',->
            addUniqueClass(@,'Selected',$s("##{oConfig.id}"))
            app.launcher.run(@dataset['page'])
