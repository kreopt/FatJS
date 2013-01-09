JAFW.Apps.std_SideMenu.HANDLER 'index',
    init:(DOMContainer,oConfig)->
        @container=DOMContainer
        @menuId=oConfig.id
        addClass(@container,'JAFW_SideMenu')

        selectItem=(item,first)->
            old=$s('.Selected',$s("##{oConfig.id}")).dataset?['page']
            addUniqueClass(item,'Selected',$s("##{oConfig.id}"))
            if first
                EMIT('MENU_STARTED',{oldApp:old,newApp:item.dataset['page']})
            else
                EMIT('MENU_CHANGED',{oldApp:old,newApp:item.dataset['page']})
        if oConfig.items.length
            selectItem($s('li',$s("##{oConfig.id}")),true)
        addEventBySelector "##{oConfig.id} li",'click',->selectItem(@,false)
