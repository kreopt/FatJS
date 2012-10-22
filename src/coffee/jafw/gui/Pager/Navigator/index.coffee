CMP 'jafw.gui.Pager.Navigator',
    __forms:['@index']
    _init:->
        @CONNECT 'PAGE_CHANGED','onPageChanged'
        @currentPage=1
    bindToView:(@view)->
        @view.binded[@UID]=@
    onPageChanged:({pageIndex,viewId,navId})->
        return if viewId!=@view.UID
        @currentPage=pageIndex
        pageCount=Math.ceil(@view.recordCount / @view.recordsPerPage)
        @RENDER '@index',@container,{
                pageCount:pageCount,
                currentPage:pageIndex,
                left: if pageIndex<6 then Math.min(6,pageCount) else 2,
                middle:Math.min(pageIndex+1,pageCount),
                right:if pageIndex>Math.max(0,pageCount-4) then Math.max(1,pageCount-5) else Math.max(1,pageCount-1),
            }
        a=@
        addEventBySelector '.PageIndex',@container,'click',->
            if a.currentPage!=Number(@dataset['idx'])
                a.EMIT 'PAGE_CHANGED',{pageIndex:Number(@dataset['idx']),viewId:a.view.UID,navId:a.UID}
        addEventBySelector '.PrevPage',@container,'click',->
            if a.currentPage>1
                a.EMIT 'PAGE_CHANGED',{pageIndex: a.currentPage-1,viewId:a.view.UID,navId:a.UID}
        addEventBySelector '.NextPage',@container,'click',->
            if a.currentPage<Math.ceil(a.recordCount / a.recordsPerPage)
                a.EMIT 'PAGE_CHANGED',{pageIndex:a.currentPage+1,viewId:a.view.UID,navId:a.UID}
    show:->
        assert(@view?)
        @view.recordCount=0
        @view.pageFrom=0
        @view.pageTo=0
        @EMIT 'PAGE_CHANGED',{pageIndex:@currentPage,viewId:@view.UID,navId:@UID}