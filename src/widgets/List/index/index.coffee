JAFW.Apps.std_List.HANDLER 'index',
    init:(DOMContainer,{items,view})->
        DOMContainer.innerHTML=''
        fragment=document.createDocumentFragment()
        for item,i in items
            itemDOM=document.createElement('div')
            itemDOM.className='ListItem'
            itemDOM.dataset['idx']=i
            JAFW.run itemDOM,view,item
            fragment.appendChild(itemDOM)
        DOMContainer.appendChild(fragment)
