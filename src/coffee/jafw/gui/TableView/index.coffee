CMP 'jafw.gui.TableView',
    __forms:['@table']
    __css:['gui/TableView']
    _init:(oConfig)->
        @rows=oConfig.rows
        rowsToRender=@rows.slice(0,oConfig.maxRows)
        @RENDER '@table',oConfig.container,{header:oConfig.header,rows:rowsToRender,width:oConfig.width}
