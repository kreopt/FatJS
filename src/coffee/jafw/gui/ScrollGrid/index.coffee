_p={items:[],fixed:{},visible:{},pos:{},w:0,h:0}
CMP 'jafw.gui.ScrollGrid',
    ###
        properties:
            items:[[{...,__DOM__}]]
            fixed:{hl,hr,vt,vb}
            visible:{h,v}
            pageSize
    ###
    _init:->
        @id=@config.id
        @__('pageSize',{
            get:->_p.pageSize,
            set:(oVal)->
                try
                    _p.pageSize=parseInt(oVal)
                catch e
                    DEBUG 'Bad property value'
        })
        @__('fixed',{
            set:(oVal)->
                if typeof(oVal)==typeof({})
                    _p.fixed.hl=oVal.hl
                    _p.fixed.hr=oVal.hr
                    _p.fixed.vt=oVal.vt
                    _p.fixed.vb=oVal.vb
                else
                    DEBUG 'Bad property value'
        })
        @__('visible',{
            set:(oVal)->
                if typeof(oVal)==typeof({})
                    _p.visible.h=oVal.h
                    _p.visible.v=oVal.v
                else
                    DEBUG 'Bad property value'
        })
        @__('items',{
            get:->_p.items,
        })
        #TODO: initialize items
        @grid=$c('table')
        @grid.appendChild($c('tbody'))
        y=0
        @items.forEach (row)->
            rowDOM=$c('tr')
            rowDOM.dataset['y']=y++
            x=0
            row.forEach (item)->
                cellDOM=$c('td')
                cellDOM.dataset['x']=x++
                cellDOM.dataset[key]=item.data[key] for key of item.data
                item.__DOM__=cellDOM
            row.__DOM__=row
        #TODO: display initial items
        if not _p.h
            _p.h=@items.length
        if not _p.w
            _p.w=@items[0].length
        y=Math.min(_p.w,@items.length)
        x=Math.min(_p.h,@items[0].length)
        [0..y].forEach (row)->
            row=@items[y].__DOM__
            [0..x].forEach (col)->
                row.appendChild @items[y][x]
        @grid.childNodes[0].appendChild(row)

    cell:(x,y)->
        i=@items
        if i.length<y and i[y].length<x
            return i[y][x]
        else
            throw 'No such cell'
    addRow:(aRow)->
        _p.w=aRow.length if _p.w<aRow.length
        _p.h=@items.length
    scroll:(iHorizontal,iVertical)->
        newPos={x:_p.pos.x+iHorizontal,y:_p.pos.y+iVertical}
        newPos.x=_p.w-1 if newPos.x>=_p.w
        newPos.y=_p.h-1 if newPos.y>=_p.h
        minx=Number(_p.pos.x)
        maxx=Number(newPos.x)
        miny=Number(_p.pos.y)
        maxy=Number(newPos.y)
        [miny..maxy].forEach (e)->removeNodesBySelector("""#{@id} tr[data-y="#{e}"]""")
        [minx..maxx].forEach (e)->removeNodesBySelector("""#{@id} td[data-x="#{e}"]""")
        signx=if iHorizontal<0 then -1 else 1
        signy=if iVertical<0 then -1 else 1
        rows=$a("""#{@id} tr[data-y]""")
        insertCols=(fInsertMethod)->
            rows.forEach (e)->@items[$data(e,'y')][minx..maxx].forEach((item)->fInsertMethod(item,e))
        if maxx<minx
            insertCols (item,e)->e.insertBefore(item.__DOM__,e.childNodes[0])
        else
            insertCols (item,e)->e.appendChild(item.__DOM__)
        tbl=$s("""#{@id} tbody""")
        insertRows=(fInsertMethod)->@items[miny..maxy].forEach(fInsertMethod)
        if maxy<miny
            insertRows (e)->tbl.insertBefore(e.__DOM__,tpl.childNodes[0])
        else
            insertRows (e)->tbl.appendChild(e.__DOM__)
    sort:(iColNum,fSortFunction)->