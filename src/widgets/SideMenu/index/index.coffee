JAFW.Apps.std_SideMenu.HANDLER 'index',
    init:(DOMContainer,oConfig)->
        @container=DOMContainer
        @menuId=oConfig.id
        addClass(@container,'JAFW_SideMenu')

        selectItem=(item,first)->
            old=$s('.Selected',$d($s("##{oConfig.id}")),'page')
            addUniqueClass(item,'Selected',$s("##{oConfig.id}"))
            if first
                EMIT('MENU_STARTED',{oldApp:old,newApp:$d(item,'page')})
            else
                EMIT('MENU_CHANGED',{oldApp:old,newApp:$d(item,'page')})
        if oConfig.items.length
            selectItem($s('li',$s("##{oConfig.id}")),true)
        addEventBySelector "##{oConfig.id} li",'click',->selectItem(@,false)
