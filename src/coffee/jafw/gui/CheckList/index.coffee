CMP 'jafw.gui.CheckList',
    __forms: ['@item']
    __using: ['jafw.gui.ListView']
    _init:(oConfig)->
        @__requiredConfig(oConfig,['container','id'])
        @listView=INSTANCE('jafw.gui.ListView',{container:oConfig.container,id:oConfig.id,dataField:'_checkBoxData'})
        @config={}
        @config.idField='id' if !oConfig.idField
        @config.dataField='name' if !oConfig.dataField
        @onChange=oConfig.onChange
        Object.defineProperty @,'items',
            get:->
                if @dirty
                    @selected=[]
                    @dirty=0
                    checked=$a("##{@id} .listItem input[type='checkbox']:checked")
                    @selected.push(item.parentNode.parentNode) for item in checked
                @selected
            set:(vVal)->@onSelect?()
        Object.defineProperty @,'values',
            get:->@items.map (element)->$data(element,'id')
            set:(aValues)->
                checked=$a("##{@id} .listItem input[type='checkbox']:checked")
                $rmattr(ch,'checked') for ch in checked
                @dirty=1
                @selected=[]
                for val in aValues
                    item=$s("##{@id} .listItem[data-id='#{val}'] input[type='checkbox']")
                    $attr(item,'checked','checked')
                    @selected.push item
                onSelect?()

        @put(oConfig.container,oConfig.id,if oConfig.data then oConfig.data else [])
    checkAll:->
        @selectItem(item,true) for item in @listView.items
        @onSelect?(item)
    reload:(aItems)->
        @selected=[]
        @dirty=0
        aItems=[] if not aItems?
        aItems.map (item)=>
           item._checkBoxData=@RENDER('@item',null,{item,idField:@config.idField,dataField:@config.dataField,checked:0})
        @listView.reload(aItems)
        addEventBySelector "##{@id} .listItem input[type='checkbox']",'change',=>
            @dirty=1
            @onChange?()
    put:(DOMContainer,sId,aItems)->
        @container=DOMContainer
        @id=sId
        @reload(aItems)


