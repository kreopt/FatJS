inSide.Apps.std_SideMenu.HANDLER 'index',
    init:(DOMContainer,oConfig)->
        @container=DOMContainer
        @menuId=oConfig.id
        addClass(@container,'inSide_SideMenu')
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
            selectItem(@$s('li',$s("##{oConfig.id}")),true)
        addEventBySelector "##{oConfig.id} li",'click',->selectItem(@,false)
    showIndicator:({pageName,value})->
        @hideIndicator({pageName})
        menuItem=@$s('li[data-page="'+pageName+'"]')
        indicator=$c('div')
        indicator.className='Indicator'
        indicator.innerHTML=value
        indicator.style.top=3+menuItem.offsetTop+'px'
        menuItem.appendChild(indicator)
    hideIndicator:({pageName})->
        removeNode(@$s('li[data-page="'+pageName+'"] div.Indicator'))
