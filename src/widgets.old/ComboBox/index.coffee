CMP 'jafw.gui.ComboBox',
    __forms: ['@select']
    __using: ['jafw.gui.ListView']
    __css:['lib/ComboBox']
    _init:(oConfig)->
        @__requiredConfig(oConfig,['container','id'])
        @config=oConfig
        @config.idField='id' if !oConfig.idField
        @config.dataField='name' if !oConfig.dataField

        @hide=(e)=>
            if e.target.id!=@id
                @list.style.display='none'

        Object.defineProperty @,'value',
            get:->$data($s('#'+@id+'_CB_Item'),'value')
            set:(vVal)->
                index=Array.prototype.indexOf.call($a('.listItem',@list),$s('.listItem[data-id="'+vVal+'"]',@list))
                @listView.selectItem(index,true)
                @selectItem(@listView.selected,true)

        @put(oConfig.container,oConfig.id,if oConfig.data then oConfig.data else [])
        @onSelect=oConfig.onSelect
    reload:(aItems)->
        @item.innerHTML='--'
        $data(@item,'value','')
        @listView.reload(aItems)
        if @listView.items.length
            @selectItem(@listView.items[0],true)
    put:(DOMContainer,sId,aItems)->
        @container=DOMContainer
        @id=sId
        app=@
        @RENDER '@select',@container,{id:sId}
        @list=$s('#'+sId+'_CB_List')
        @item=$s('#'+sId+'_CB_Item')
        @listView=INSTANCE('jafw.gui.ListView',{container:@list,id:sId,idField:@config.idField,dataField:@config.dataField,data:aItems})
        @listView.selectItem=(index,noevented)->
            app.selectItem(@selected,noevented)
        @reload(aItems)
        @value=@config.default if @config.default
        @item.onclick= =>
            @list.style.display=if @list.style.display=='none' then 'block' else 'none'
        $s('body').removeEventListener('click',@hide,true)
        $s('body').addEventListener('click',@hide,true)
    selectItem:(listItem,noevented)->
        @item.innerHTML=listItem[@config.dataField]
        $data(@item,'value',listItem[@config.idField])
        if not noevented
            @onSelect?(listItem)


