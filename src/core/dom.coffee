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



   getRealDisplay=(elem)->
      if (elem.currentStyle)
         return elem.currentStyle.display
      else
         if (window.getComputedStyle)
            computedStyle = window.getComputedStyle(elem, null )
            return computedStyle.getPropertyValue('display')

   displayCache = {}

   isHidden=(el)->
      width = el.offsetWidth
      height = el.offsetHeight
      tr = el.nodeName.toLowerCase() == "tr"

      return if (width == 0 && height == 0 && !tr) then true else (if width > 0 && height > 0 && !tr then false else getRealDisplay(el))

   oHolder.$toggle=(el)->
      if isHidden(el) then show(el) else hide(el)

   oHolder.$hide = (DOMNode)->
      if !DOMNode.getAttribute('displayOld')
         DOMNode.setAttribute("displayOld", DOMNode.style.display)
      DOMNode.style.display = "none"

   oHolder.$show = (DOMNode)->
      return if (getRealDisplay(DOMNode) != 'none')

      old = DOMNode.getAttribute("displayOld");
      DOMNode.style.display = old || "";

      if ( getRealDisplay(DOMNode) == "none" )
         nodeName = DOMNode.nodeName
         body = document.body

         if ( displayCache[nodeName] )
            display = displayCache[nodeName]
         else
            testElem = document.createElement(nodeName)
            body.appendChild(testElem)
            display = getRealDisplay(testElem)

            if (display == "none" )
               display = "block"

            body.removeChild(testElem)
            displayCache[nodeName] = display

         DOMNode.setAttribute('displayOld', display)
         DOMNode.style.display = display

   oHolder.dragSetup = (event, oData, sEffect)->
      event.dataTransfer.setData('text/plain', JSON.stringify(oData))
      event.dataTransfer.effectAllowed = sEffect
      event.dataTransfer.dropEffect = sEffect
   oHolder.addEvents = (DOMNodes, sEventName, fCallback)->
      holder=if @ then @ else window
      node.addEventListener(sEventName, ((e)->fCallback.call(@,e,holder)), false) for node in DOMNodes
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
   oHolder.setupEvents = (oEventListeners,DOMScope)->
      scope = oHolder.$scope(DOMScope)
      for selector, events of oEventListeners
         if selector[0]=='$'
            selector=selector.substr(1)
            single=true
         else if selector[0]=='#'
            single=true
         else
            single=false
         nodes=if single then [$s(selector, scope)] else nodes=$a(selector, scope)
         for event, listeners of events
            if typeof(listeners)==typeof(->)
               oHolder.addEvents(nodes, event, listeners)
            else
               for listenerName, listener of listeners
                  oHolder.addEvents(nodes, event, listener)

installDOMWrappers(self, document)
