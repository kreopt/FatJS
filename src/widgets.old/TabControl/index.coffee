_currentTab=0;
CMP 'jafw.gui.TabControl',
    __forms:['@tab','@panel']
    __css:['lib/TabControl']
    _init:()->
        @_tabs={}
    put:(DOMPanelContainer,DOMContentContainer,sId)->
        @panelContainer=DOMPanelContainer
        @contentContainer=DOMContentContainer
        @id=sId
        DOMPanelContainer?.innerHTML=@RENDER '@panel',null,{id:sId}
        @tabPanel=$s('#'+sId)
        for index,tab of @_tabs
            @_putTab tab
        cmp=@
        for index,tab of @_tabs
            break
        if index
            @selectTab(index)
    _putTab:(oTab)->
        @tabPanel.insertAdjacentHTML 'beforeend',@RENDER '@tab',null,oTab

    selectTab:(iTabIndex)->
        _currentTab=iTabIndex
        addUniqueClass $s('#'+@id+' .Tab[data-index="'+iTabIndex+'"]'),'Selected',@panelContainer
        @_tabs[iTabIndex].contentGenerator?.call(@,@contentContainer,iTabIndex)
        @_tabs[iTabIndex].init?.call(@,iTabIndex)

    addTab:({attr,head,contentGenerator,init})->
        a=attr;
        if not a.index
            index=JAFW.nextID()
            a.index=index
        else
            index=a.index
        if @panelContainer?
            if not @_tabs[index]?
                @_tabs[index]={attr:a,head,contentGenerator,init}
                @_putTab @_tabs[index]
                cmp=@
                cmp.panelContainer.style.width=cmp.panelContainer.clientWidth+$s('#'+@id+' .Tab[data-index="'+index+'"]').clientWidth+'px';
                addEventBySelector '#'+@id+' .Tab[data-index="'+index+'"]','click',->
                    cmp.selectTab(@dataset['index'])
            else
                @selectTab(index)

    removeTab:(iIndex)->
        if (@_tabs[iIndex])
            @panelContainer.style.width=@panelContainer.clientWidth-$s('#'+@id+' .Tab[data-index="'+index+'"]').clientWidth+'px';
            removeNodesBySelector('#'+@id+' .Tab[data-index="'+iIndex+'"]',@panelContainer)
            delete @_tabs[iIndex]
            for index,tab of @_tabs
                break
            if index
                @selectTab(index)
            else
                @contentContainer.innerHTML=''

CPROPERTY 'TabControl::currentTab',
    get:->_currentTab
    set:->