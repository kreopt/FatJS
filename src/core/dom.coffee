'use strict';
# COMPATIBILITY
if not Element.prototype.hasOwnProperty('classList')
   Object.defineProperty(Element.prototype, 'classList', {
      get : ->
         a=@
         return {
         contains : (className)->
            String(a.className).split(' ').indexOf(className) + 1
         add : (className)->
            classList=String(a.className).split(' ')
            if not a.classList.contains(className)
               classList.push(className)
               a.className = classList.join('')
         remove : (className)->
            classList=String(a.className).split(' ')
            classIndex=a.classList.contains(className)
            if classIndex
               classList.splice(classIndex - 1, 1)
               a.className = classList.join('')
         toggle : (className)->
            classList=String(a.className).split(' ') - 1
            classIndex=classList.indexOf(className)
            if classIndex
               classList.splice(classIndex, 1)
            else
               classList.push(className)
            a.className = classList.join('')
         }
   })

self.installDOMWrappers = (oHolder, DOMToplevelScope)->
   oHolder.$scope = ((DOMToplevelScope)->(DOMScope)->if DOMScope? then DOMScope else DOMToplevelScope)(DOMToplevelScope)

   # DOM Element Class Mapping
   oHolder.$S = (sCPath, DOMScope)->
      classes=sCPath.split('.')
      DOMScope = DOMToplevelScope if not DOMScope
      el=DOMScope
      classes.forEach (e)=>el = $s('.' + e, el)
      el
   oHolder.$A = (sCPath, DOMScope)->
      classes=sCPath.split('.')
      DOMScope = DOMToplevelScope if not DOMScope
      el=DOMScope
      classes.forEach (e, i)=>el = if (i < classes.length - 1) then $s('.' + e, el) else $a('.' + e, el)
      el
   oHolder.$p = (sSelector, DOMScope)->
      throw 'Child node must be specified!' if not DOMScope
      parent=DOMScope
      while parent.parentNode
         parent = parent.parentNode
         # TODO: get only direct children
         matches=parent.parentNode?.querySelectorAll(sSelector)
         for match in matches
            if match == parent
               return parent
      return null
   oHolder.$s = (sSelector, DOMScope)->
      el=oHolder.$scope(DOMScope).querySelector(sSelector)
      if not el
         el = document.createElement('empty')
         el.isEmpty = true
      return el
   oHolder.$a = (sSelector, DOMScope)->
      r=oHolder.$scope(DOMScope).querySelectorAll(sSelector)
      return (item for item in r)
   oHolder.$c = (sElemName)->document.createElement(sElemName)
   oHolder.$e = (sSelector, sEventType, sEventName, aEventArgs)->
      fireOnThis = $s(sSelector)
      evObj = document.createEvent(sEventType);
      evObj.initEvent.apply(this, aEventArgs);
      fireOnThis.dispatchEvent(evObj);

   oHolder.$next = (DOMNode)->
      sibling=DOMNode.nextSibling
      sibling = sibling.nextSibling while (sibling && sibling.nodeType != 1)
      return sibling
   oHolder.$prev = (DOMNode)->
      sibling=DOMNode.previousSibling
      sibling = sibling.previousSibling while (sibling && sibling.nodeType != 1)
      return sibling
   oHolder.$attr = (DOMNode, sAttr, vValue)->
      return DOMNode.getAttribute(sAttr) if not vValue?
      DOMNode.setAttribute(sAttr, vValue)
      DOMNode[sAttr] = vValue
   oHolder.$rmattr = (DOMNode, sAttr)->
      DOMNode[sAttr]=null
      DOMNode.removeAttribute(sAttr)
   oHolder.$tglattr = (DOMNode, sAttr, vValue)->
      if oHolder.$attr(DOMNode, sAttr)
         oHolder.$rmattr(DOMNode, sAttr)
      else
         oHolder.$attr(DOMNode,sAttr, vValue)
   oHolder.$d = (DOMNode, sName, vValue = null)->
      # COMPATIBILITY
      if not ('dataset' in DOMNode)
         return DOMNode.getAttribute('data-' + sName) if not vValue?
         DOMNode.setAttribute('data-' + sName, vValue)
      else
         return DOMNode.dataset[sName] if not vValue?
         DOMNode.dataset[sName] = vValue
   oHolder.toggleClass = (DOMNode, className)->DOMNode.classList.toggle(className)
   oHolder.hasClass = (DOMNode, className)->if DOMNode.classList then DOMNode.classList.contains(className) else false
   oHolder.addClass = (DOMNode, className)->DOMNode.classList.add(className)
   oHolder.addUniqueClass = (DOMNode, sClassName, DOMScope)->
      DOMScope = oHolder.$scope(DOMScope)
      oldNodes=DOMScope.querySelectorAll('.' + sClassName)
      removeClass(node, sClassName) for node in oldNodes
      addClass(DOMNode, sClassName)
   oHolder.removeClass = (DOMNode, className)->DOMNode.classList.remove(className)
   oHolder.removeNode = (DOMNode)->DOMNode.parentNode.removeChild(DOMNode) if DOMNode.parentNode
   oHolder.insertAfter = (DOMNode, sHtml)->DOMNode.insertAdjacentHTML('afterend', sHtml)
   oHolder.insertBefore = (DOMNode, sHtml)->DOMNode.insertAdjacentHTML('beforebegin', sHtml)

   oHolder.dragSetup = (event, oData, sEffect)->
      event.dataTransfer.setData('text/plain', JSON.stringify(oData))
      event.dataTransfer.effectAllowed = sEffect
      event.dataTransfer.dropEffect = sEffect
   oHolder.addEvents = (DOMNodes, sEventName, fCallback)->
      node.addEventListener(sEventName, fCallback, false) for node in DOMNodes
   oHolder.addEventBySelector = (sSelector, DOMScope, sEventName, fCallback)->
      if arguments.length < 4
         fCallback = sEventName
         sEventName = DOMScope
         DOMScope = undefined
      holder = if @ then @ else window
      DOMNodes=holder.$a(sSelector, DOMScope)
      addEvents(DOMNodes, sEventName, fCallback)
   oHolder.removeNodesBySelector = (sSelector, DOMScope)->
      DOMScope = document if not DOMScope?
      DOMNodes=DOMScope.querySelectorAll(sSelector)
      for node in DOMNodes
         node.parentNode.removeChild(node)
installDOMWrappers(self, document)