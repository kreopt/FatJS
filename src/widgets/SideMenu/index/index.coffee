JAFW.Apps.std_SideMenu.HANDLER 'index',
    init:(DOMContainer,oConfig)->
        @container=DOMContainer
        @menuId=oConfig.id
        addClass(@container,'JAFW_SideMenu')

        selectItem=(item)->
            old=$('Selected',$s("##{oConfig.id}")).dataset?['page']
            addUniqueClass(item,'Selected',$s("##{oConfig.id}"))
            EMIT('MENU_CHANGED',{oldApp:old,newApp:item.dataset['page']})
        if oConfig.items.length
            selectItem($s('li',$s("##{oConfig.id}")))
        addEventBySelector "##{oConfig.id} li",'click',->selectItem(@)
