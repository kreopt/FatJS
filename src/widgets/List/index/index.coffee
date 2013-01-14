JAFW.Apps.std_List.HANDLER 'index',
    init:(DOMContainer,{items,view})->
        DOMContainer.innerHTML=''
        fragment=document.createDocumentFragment()
        for item,i in items
            itemDOM=document.createElement('div')
            itemDOM.className='ListItem'
            $d(itemDOM,'idx',i)
            JAFW.run itemDOM,view,item
            fragment.appendChild(itemDOM)
        DOMContainer.appendChild(fragment)
