CMP 'jafw.gui.Pager',
    __forms:['@pager']
    _init:(oConfig)->
        if typeof(oConfig.loader) != typeof(->)
            throw 'Pager loader unitialized!'
        @loader=oConfig.loader
        @pageItems={}
        @page=1;
        @pageCount=1;
        @loadCount=if oConfig.loadCount then (oConfig.loadCount-1) / 2 else 2
        @itemsCount=if oConfig.itemsCount then oConfig.itemsCount else 25
    put:(DOMContainer,oPageContainer)->
        if typeof(oPageContainer.put)!=typeof(->)
            throw 'oPageContainer must implement put(aItems) method'
        @pageContainer=oPageContainer
        @container=DOMContainer
        @loader 0,(oResponse)=>
            @pageItems=[]
            @pageCount=Math.ceil(oResponse/@itemsCount)
            if @page>@pageCount
                @page=1
            @getPage(@page)
    renewPager:(iPageIndex)->
        @page=iPageIndex if iPageIndex
        @RENDER '@pager',@container,{max:@pageCount,current:@page}
        app=@
        addEventBySelector '.Page',@container,'click', ->
            app.getPage(@dataset['page'])
        $s('.NextPage').onclick= =>@getPage(@page+1)
        $s('.PrevPage').onclick= =>@getPage(@page-1)
    getPage:(iPageIndex)->
        iPageIndex=@page if not iPageIndex?
        iPageIndex=1 if iPageIndex<1 or iPageIndex>@pageCount
        @renewPager(iPageIndex)
        if not @pageItems[(iPageIndex-1)*@itemsCount]?
            prev=if iPageIndex-@loadCount > 0 then iPageIndex-1 else 1
            next=if iPageIndex+@loadCount <= @pageCount then iPageIndex+1 else @pageCount
            @loader "#{(prev-1)*@itemsCount}-#{(next)*@itemsCount-1}",(oResponse)=>
                @pageItems=[] #no cache
                index=(prev-1)*@itemsCount
                oResponse.forEach (item)=>@pageItems[index++]=item
                @pageContainer.put(@pageItems.slice((iPageIndex-1)*@itemsCount,(iPageIndex)*@itemsCount))
        else
            @pageContainer.put(@pageItems.slice((iPageIndex-1)*@itemsCount,(iPageIndex)*@itemsCount))