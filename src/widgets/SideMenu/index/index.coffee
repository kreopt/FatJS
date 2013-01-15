JAFW.Apps.std_SideMenu.HANDLER 'index',
    init:(DOMContainer,oConfig)->
        @container=DOMContainer
        @menuId=oConfig.id
        addClass(@container,'JAFW_SideMenu')
        CONNECT 'SHOW_INDICATOR','showIndicator',@
        CONNECT 'HIDE_INDICATOR','hideIndicator',@

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
    showIndicator:({pageName,value})->
        @hideIndicator({pageName})
        indicator=$c('div')
        indicator.className='Indicator'
        indicator.innerHTML=value
        @$s('li[data-page="'+pageName+'"]').appendChild(indicator)
    hideIndicator:({pageName})->
        removeNode(@$s('li[data-page="'+pageName+'"] div.Indicator'))
