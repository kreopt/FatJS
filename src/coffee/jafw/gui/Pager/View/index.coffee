CMP 'jafw.gui.Pager.View',
    __forms:['@list']
    _init:()->
        @CONNECT 'PAGE_CHANGED','onPageChanged'
        @recordsPerPage=25
        @recordCount=0
        @pageFrom=0
        @pageTo=0
        @pages=[]
        @binded={}
    getRecords:()->
        throw 'Not implemented!'
    show:(startIndex=0)->
        pages=@pages.slice(startIndex,startIndex+@recordsPerPage).map((e)=>RENDER(@recordTemplate,null,e))
        @RENDER '@list',@container,{pages}
    onPageChanged:({pageIndex,viewId,navId})->
        return if viewId!=@UID
        for nav of @binded
            @binded[nav].recordCount=@recordCount
            @binded[nav].recordsPerPage=@recordsPerPage
        startIndex=(pageIndex-1)*@recordsPerPage
        if @pageFrom<=pageIndex<@pageTo
            @show(startIndex)
        else
            @getRecords startIndex+1, @recordsPerPage*5,(pages)=>
                @pages=pages
                @pageFrom=pageIndex
                @pageTo=pageIndex+5
                @onPageChanged({pageIndex,viewId,navId})