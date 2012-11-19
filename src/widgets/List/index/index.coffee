JAFW.Apps.std_Pager.HANDLER 'index',
    preRender:(renderCallback,{@pageIndex,@navId,@itemCount,@itemsPerPage})->
        @currentPage=@pageIndex
        pageCount=Math.ceil(@itemCount / @itemsPerPage)
        renderCallback {
            pageCount:pageCount,
            currentPage:@pageIndex,
            left: if @pageIndex<6 then Math.min(6,pageCount) else 2,
            middle:Math.min(@pageIndex+1,pageCount),
            right:if @pageIndex>Math.max(0,pageCount-4) then Math.max(1,pageCount-5) else Math.max(1,pageCount-1),
        }
    init:(DOMContainer,{pageIndex,navId,pageCount,itemsPerPage})->
        a=@
        @addEventBySelector '.PageIndex',@container,'click',->
            if a.currentPage!=Number(@dataset['idx'])
                a.pageChange(Number(@dataset['idx']))
        @addEventBySelector '.PrevPage',@container,'click',->
            if a.currentPage>1
                a.pageChange(a.currentPage-1)
        @addEventBySelector '.NextPage',@container,'click',->
            if a.currentPage<Math.ceil(a.itemCount / a.itemsPerPage)
                a.pageChange(a.currentPage+1)
        @pageChange(1)
    pageChange:(pageIndex)->
        startIndex=(pageIndex-1)* @recordsPerPage
        amount=pageIndex* @recordsPerPage
        EMIT 'PAGE_SELECTED:'+ @UID,{startIndex,amount}