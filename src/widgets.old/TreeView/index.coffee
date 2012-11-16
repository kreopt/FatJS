CMP 'jafw.gui.TreeView',
    __forms:['@item']
    __css:['lib/lib/treeView.css']
    _init:->
    put:(DOMContainer,oData)->
        DOMContainer.innerHTML=@_handleItem(oData,true)
        addEventBySelector 'hgroup','click',->
            toggleClass $s('div.TreeItemBody',@parentNode),'hidden'
    _handleItem:(oItem,isRoot)->
        if not oItem.head
            html=@RENDER '@item',null,{body:oItem.body,root:isRoot}
        else
            html=''
            if typeof(oItem.body)==typeof([])
                for body in oItem.body
                    html+=@_handleItem(body,false)
                html=@RENDER '@item',null,{head:oItem.head,body:html,root:isRoot}
            else
                html+=@RENDER '@item',null,{head:oItem.head,body:@_handleItem(body,false),root:isRoot}
        html