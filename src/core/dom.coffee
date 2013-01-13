'use strict';
self.installDOMWrappers=(oHolder,DOMToplevelScope)->
    scope=(DOMScope)->if DOMScope? then DOMScope else DOMToplevelScope
    # DOM Element Class Mapping
    oHolder.$S=(sCPath,DOMScope)->
        classes=sCPath.split('.')
        DOMScope=DOMToplevelScope if not DOMScope
        el=DOMScope
        classes.forEach (e)=>el=$s('.'+e,el)
        el
    oHolder.$A=(sCPath,DOMScope)->
        classes=sCPath.split('.')
        DOMScope=DOMToplevelScope if not DOMScope
        el=DOMScope
        classes.forEach (e,i)=>el=if (i<classes.length-1) then $s('.'+e,el) else $a('.'+e,el)
        el
    oHolder.$s=(sSelector,DOMScope)->
        el=scope(DOMScope).querySelector(sSelector)
        if not el
            el=document.createElement('empty')
            el.isEmpty=true
        return el
    oHolder.$a=(sSelector,DOMScope)->
        r=scope(DOMScope).querySelectorAll(sSelector)
        return (item for item in r)
    oHolder.$c=(sElemName)->document.createElement(sElemName)
    oHolder.$e=(sSelector,sEventType,sEventName,aEventArgs)->
        fireOnThis = $s(sSelector)
        evObj = document.createEvent(sEventType);
        evObj.initEvent.apply( this, aEventArgs);
        fireOnThis.dispatchEvent(evObj);

    oHolder.$next=(DOMNode)->
        sibling=DOMNode.nextSibling
        sibling = sibling.nextSibling while (sibling && sibling.nodeType != 1)
        return sibling
    oHolder.$prev=(DOMNode)->
        sibling=DOMNode.previousSibling
        sibling = sibling.previousSibling while (sibling && sibling.nodeType != 1)
        return sibling
    oHolder.$attr=(DOMNode,sAttr,vValue)->
        return DOMNode.getAttribute(sAttr) if not vValue?
        DOMNode.setAttribute(sAttr,vValue)
        DOMNode[sAttr]=vValue
    oHolder.$rmattr=(DOMNode,sAttr)->DOMNode.removeAttribute(sAttr)
    oHolder.$data=(DOMNode,sName,vValue)->
        return DOMNode.dataset[sName] if not vValue?
        DOMNode.dataset[sName]=vValue
    oHolder.toggleClass=(DOMNode,className)->DOMNode.classList.toggle(className)
    oHolder.hasClass=(DOMNode,className)->if DOMNode.classList then DOMNode.classList.contains(className) else false
    oHolder.addClass=(DOMNode,className)->DOMNode.classList.add(className)
    oHolder.addUniqueClass=(DOMNode,sClassName,DOMScope)->
        DOMScope=document if not DOMScope?
        oldNodes=DOMScope.querySelectorAll('.'+sClassName)
        removeClass(node,sClassName) for node in oldNodes
        addClass(DOMNode,sClassName)
    oHolder.removeClass=(DOMNode,className)->DOMNode.classList.remove(className)
    oHolder.removeNode=(DOMNode)->DOMNode.parentNode.removeChild(DOMNode) if DOMNode.parentNode
    oHolder.insertAfter=(DOMNode,sHtml)->DOMNode.insertAdjacentHTML('afterend',sHtml)
    oHolder.insertBefore=(DOMNode,sHtml)->DOMNode.insertAdjacentHTML('beforebegin',sHtml)

    oHolder.dragSetup=(event,oData,sEffect)->
        event.dataTransfer.setData('text/plain',JSON.stringify(oData))
        event.dataTransfer.effectAllowed=sEffect
        event.dataTransfer.dropEffect = sEffect
    oHolder.addEvents=(DOMNodes,sEventName,fCallback)->
        node.addEventListener(sEventName,fCallback,false) for node in DOMNodes
    oHolder.addEventBySelector=(sSelector,DOMScope,sEventName,fCallback)->
        if arguments.length<4
            fCallback=sEventName
            sEventName=DOMScope
            DOMScope=undefined
        DOMNodes=$a(sSelector,DOMScope)
        addEvents(DOMNodes,sEventName,fCallback)
    oHolder.removeNodesBySelector=(sSelector,DOMScope)->
        DOMNodes=DOMProxy::scope(DOMScope).querySelectorAll(sSelector)
        for node in DOMNodes
            node.parentNode.removeChild(node)
installDOMWrappers(self,document)