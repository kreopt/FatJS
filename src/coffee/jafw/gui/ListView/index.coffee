CMP 'jafw.gui.ListView',
    __forms: ['@listView','@listItem']
    #initializer
    _init:(oConfig)->
        @__requiredConfig(oConfig,['container','id'])
        @__selected=null
        @config={} if !@config
        @config.idField= oConfig.idField if oConfig.idField
        @config.dataField= oConfig.dataField if oConfig.dataField
        @put(oConfig.container,oConfig.id,if oConfig.data then oConfig.data else [])
        #USER DEFINABLE FUNCTIONS

        @_addItem=(vItem)->
        @_removeItem=(iItemIndex)->
        @_selectItem=(iItemIndex,noevented)->
        #USER INTERFACE
        Object.defineProperties @,
            addItem:
                get:->@__addItem
                set:(vVal)->@_addItem=vVal
            removeItem:
                get:->@__removeItem
                set:(vVal)->@_removeItem=vVal
            selectItem:
                get:->@__selectItem
                set:(vVal)->@_selectItem=vVal
            selected:
                get:->@__selected
            itemIndex:
                get:->(vItem)->
                    items=$a('tr.listItem',@view)
                    for item,itemIndex in items
                        if item is vItem
                            break
                    itemIndex=-1 if itemIndex==items.length
                    itemIndex
            items:
                get:->@__items
            moveUp:
                get:->@__moveUp
            moveDown:
                get:->@__moveDown
    reload:(aItems)->
        if not typeof aItems is typeof []
            throw 'Items must be an array'
        @__items=aItems
        itemsHTML=''
        index=0
        for item in @__items
            itemsHTML+=@RENDER '@listItem',null,{item,idField:@idField,dataField:@dataField,index:index++}
        @view.innerHTML=itemsHTML
        @__setupEvents()
    put:(DOMContainer,sId,aItems)->
    #TODO: aItems must be an array!
        return false if not typeof aItems is typeof []
        @id=sId
        @container=DOMContainer
        @RENDER '@listView',@container,{id:@id}
        @idField=if @config.idField then @config.idField else 'id'
        @dataField=if @config.dataField then @config.dataField else 'name'
        @view=$s('#'+@id)
        @reload(aItems)
    __setupEvents:->
        app=@
        addEventBySelector 'tr.listItem',@view,'click',->app.__selectItem.call(app,app.itemIndex(@))
    #properties
    __items:[]
    #CORE FUNCTIONS
    __moveUp:(iItemIndex)->
        return if iItemIndex<1
        #TODO: don't work:(
        item=$s('.listItem[data-id="'+@__items[iItemIndex][@idField]+'"]')
        item1=$s('.listItem[data-id="'+@__items[iItemIndex-1][@idField]+'"]')
        item.parentNode.replaceChild(item,item1)
        item.parentNode.replaceChild(item1,item)
        [@__items[iItemIndex],@__items[iItemIndex-1]]=[@__items[iItemIndex-1],@__items[iItemIndex]]

    __moveDown:(iItemIndex)->
        return if iItemIndex>= @__items.length
        item=$s('.listItem[data-id="'+@__items[iItemIndex][@idField]+'"]')
        item1=$s('.listItem[data-id="'+@__items[iItemIndex+1][@idField]+'"]')
        item.parentNode.replaceChild(item,item1)
        item.parentNode.replaceChild(item1,item)
        [@__items[iItemIndex],@__items[iItemIndex+1]]=[@__items[iItemIndex+1],@__items[iItemIndex]]

    __addItem:(vItem)->
        @__items.push vItem
        @_addItem(vItem)
        last=$a('tr.listItem',@view)
        last=last[last.length-1]
        if last
            after last,@RENDER '@listItem',null,vItem
        else
            @RENDER '@listItem',@view,vItem
        @__setupEvents()
    __removeItem:(iItemIndex)->
        if @__items.length<=iItemIndex || not iItemIndex?
            return
        @__items.splice(iItemIndex,1)
        @_removeItem.call(@,iItemIndex)
        items=$a('.listItem',@view)
        items[iItemIndex].parentNode.removeChild(items[iItemIndex])
    __selectItem:(iItemIndex,noevented)->
        @__selected=@__items[iItemIndex]
        addUniqueClass($a('tr.listItem',@view)[iItemIndex],'listItemSelected',@view)
        @_selectItem.call(@,iItemIndex,noevented)