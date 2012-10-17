'use strict';
class DOMProxy
    scope:(DOMScope)->if DOMScope? then DOMScope else DOCUMENT
    _apply:(DOMWrapped,fFunction)->(args...)->
        args.unshift(this)
        fFunction.apply(this,args)
    _wrap:(DOMNodes)->
        wrapped=if DOMNodes then DOMNodes else DOCUMENT.createElement('empty')
        wrapped.isEmpty=true if wrapped.tagName=='EMPTY'
        @_apply(wrapped,hasClass)
        wrapped

window.nextSibling=(item)->
    sibling=item.nextSibling
    sibling = sibling.nextSibling while (sibling && sibling.nodeType != 1)
    return sibling
window.prevSibling=(item)->
    sibling=item.previousSibling
    sibling = sibling.previousSibling while (sibling && sibling.nodeType != 1)
    return sibling
window.$s=(sSelector,DOMScope)->
    try
        return DOMProxy::_wrap(DOMProxy::scope(DOMScope).querySelector(sSelector))
    catch exception
        DEBUG 'Invalid selector: ' + sSelector
        return null
window.$a=(sSelector,DOMScope)->
    r=DOMProxy::scope(DOMScope).querySelectorAll(sSelector)
    rr=[]
    rr.push(item) for item in r
    rr
window.$c=(sElemName)->DOCUMENT.createElement(sElemName)
window.$e=(sSelector,sEventName)->
    fireOnThis = $s(sSelector)
    evObj = document.createEvent('MouseEvents');
    evObj.initEvent( 'click', true, true );
    fireOnThis.dispatchEvent(evObj);
window.$attr=(DOMNode,sAttr,vValue)->
    if not vValue?
        return DOMNode.getAttribute(sAttr)
    DOMNode.setAttribute(sAttr,vValue)
    DOMNode[sAttr]=vValue
window.$rmattr=(DOMNode,sAttr)->
    DOMNode.removeAttribute(sAttr)
window.$data=(DOMNode,sName,vValue)->
    if not vValue?
        return DOMNode.dataset[sName]
    DOMNode.dataset[sName]=vValue
window.$d=document
window.$w=window

# DOM Element Class Mapping
window.$S=(sCPath,DOMScope)->
    classes=sCPath.split('.')
    DOMScope=$d if not DOMScope
    el=DOMScope
    classes.forEach (e)=>el=$s('.'+e,el)
    el
window.$A=(sCPath,DOMScope)->
    classes=sCPath.split('.')
    DOMScope=$d if not DOMScope
    el=DOMScope
    classes.forEach (e,i)=>
        if (i<classes.length-1)
            el=$s('.'+e,el)
        else
            el=$a('.'+e,el)
    el

window.toggleClass=(DOMNode,className)->DOMNode.classList.toggle(className)
window.hasClass=(DOMNode,className)->if DOMNode.classList then DOMNode.classList.contains(className) else false
window.addClass=(DOMNode,className)->DOMNode.classList.add(className)
window.addUniqueClass=(DOMNode,sClassName,DOMScope)->
    DOMScope=DOCUMENT if not DOMScope?
    oldNodes=DOMScope.querySelectorAll('.'+sClassName)
    removeClass(node,sClassName) for node in oldNodes
    addClass(DOMNode,sClassName)
window.removeClass=(DOMNode,className)->DOMNode.classList.remove(className)
window.dragSetup=(event,oData,sEffect)->
    event.dataTransfer.setData('text/plain',JSON.stringify(oData))
    event.dataTransfer.effectAllowed=sEffect
    event.dataTransfer.dropEffect = sEffect
window.addEvents=(DOMNodes,sEventName,fCallback)->
    for node in DOMNodes
        node['on'+sEventName]=fCallback
window.addEventBySelector=(sSelector,DOMScope,sEventName,fCallback)->
    if arguments.length<4
        fCallback=sEventName
        sEventName=DOMScope
        DOMScope=undefined
    DOMNodes=$a(sSelector,DOMScope)
    addEvents(DOMNodes,sEventName,fCallback)
window.removeNodesBySelector=(sSelector,DOMScope)->
    DOMNodes=DOMProxy::scope(DOMScope).querySelectorAll(sSelector)
    for node in DOMNodes
        node.parentNode.removeChild(node)
window.removeNode=(DOMNode)->
    DOMNode.parentNode.removeChild(DOMNode) if DOMNode.parentNode
window.after=(DOMNodeSibling,sHtml)->
    DOMNodeSibling.insertAdjacentHTML('afterend',sHtml)
window.before=(DOMNodeSibling,sHtml)->
    DOMNodeSibling.insertAdjacentHTML('beforebegin',sHtml)