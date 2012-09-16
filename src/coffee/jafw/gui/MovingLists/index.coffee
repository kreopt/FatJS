CMP 'jafw.gui.MovingLists',
    __forms:['@view']
    __using:['jafw.gui.ListView']
    #IN:@id,[{header,items},...]
    put:(DOMContainer,sId,aLists)->
        #each list must contain list items only
        @id=sId
        @container=DOMContainer
        @__lists=aLists
        #render view
        @RENDER '@view',@container,{id:@id,lists:@__lists}
        @listArray=[]
        for list,listIndex in @__lists
            @listArray[listIndex]=INSTANCE('jafw.gui.ListView')
            @listArray[listIndex].put($s('#'+@id+'_LC_'+listIndex),@id+'_L_'+listIndex,list.items)

        i=0
        while i < listIndex
            $s('#'+@id+'_ADD_'+i).onclick= ((i)=> =>
                if @listArray[i].selected?
                    @listArray[i+1].addItem(@listArray[i].selected)
                    @listArray[i].removeItem(@listArray[i].itemIndex($s('.listItemSelected',@listArray[i].view))))(i)
            $s('#'+@id+'_DEL_'+i).onclick= ((i)=> =>
                if @listArray[i+1].selected?
                    @listArray[i].addItem(@listArray[i+1].selected)
                    @listArray[i+1].removeItem(@listArray[i+1].itemIndex($s('.listItemSelected',@listArray[i+1].view))))(i)
            ++i
