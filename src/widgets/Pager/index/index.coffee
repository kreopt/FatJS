JAFW.Apps.std_Pager.HANDLER 'index',
    preRender:(renderCallback,{@pageIndex,@navId,@itemCount,@itemsPerPage})->
        CONNECT 'RESET_PAGER','reset',@,@navId
        @render=renderCallback
        @reset({@pageIndex,@navId,@itemCount,@itemsPerPage})
    reset:({pageIndex,itemCount,itemsPerPage})->
        @pageIndex=pageIndex if pageIndex
        @itemCount=itemCount if itemCount
        @itemsPerPage=itemsPerPage if itemsPerPage
        pageCount=Math.ceil(@itemCount / @itemsPerPage)
        @pageIndex=pageCount if @pageIndex>pageCount
        @currentPage=@pageIndex
        @render {
            pageCount:pageCount,
            currentPage:@pageIndex,
            left: if @pageIndex<6 then Math.min(6,pageCount) else 2,
            middle:Math.min(@pageIndex+1,pageCount),
            right:if @pageIndex>Math.max(0,pageCount-4) then Math.max(1,pageCount-5) else Math.max(1,pageCount-1),
        }
    init:(DOMContainer,{pageIndex,navId,pageCount,itemsPerPage})->
        a=@
        @addEventBySelector '.PageIndex','click',->
            if a.currentPage!=Number($d(@,'idx'))
                addUniqueClass(@,'Selected',@parentNode)
                a.pageChange(Number($d(@,'idx')))
        @addEventBySelector '.PrevPage','click',->
            if a.currentPage>1
                pageElement=$s('.PageIndex[data-idx="'+(a.currentPage-1)+'"]',@parentNode)
                addUniqueClass(pageElement,'Selected',@parentNode)
                a.pageChange(a.currentPage-1)
        @addEventBySelector '.NextPage','click',->
            if a.currentPage<Math.ceil(a.itemCount / a.itemsPerPage)
                pageElement=$s('.PageIndex[data-idx="'+(a.currentPage+1)+'"]',@parentNode)
                addUniqueClass(pageElement,'Selected',@parentNode)
                a.pageChange(a.currentPage+1)
        @pageChange(pageIndex)
    pageChange:(pageIndex)->
        startIndex=(pageIndex-1)* @itemsPerPage
        amount=pageIndex* @itemsPerPage
        @currentPage=pageIndex
        EMIT 'PAGE_SELECTED',{startIndex,amount},@navId