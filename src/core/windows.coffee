class Notifier
   success : ({head,body})->inSide.Notifier.show(head, body, 'Success')
   alert : ({head,body})->inSide.Notifier.show(head, body, 'Alert', 0)
   banner : ({head,body})->inSide.Notifier.show(head, body, 'Banner')
   error : ({body})->inSide.Notifier.show('Ошибка', body, 'Error')
   notify : ({head,body})->inSide.Notifier.show(head, body, 'Notify')
   show : (sHead, sBody, sType = 'Notify', iTimeout = 5000)->
      notify=$c('div')
      sHead = '' if not sHead
      #TODO: сделать более гибким не прибегая к шаблонам
      notify.innerHTML = """<div class="NotifyHead">#{sHead}</div><div class="NotifyText">#{sBody}</div>""";
      notify.className = 'Notify Notify_' + sType;
      notifications=$a('.Notify_' + sType);
      height=0;
      for notification in notifications
         height += notification.clientHeight + 12 + 3;
      notify.style.top = height + 'px'
      $s('body').appendChild(notify);
      if iTimeout
         notify.timeout = setTimeout((=>@hide(notify, sType)), iTimeout)
      else
         notify.onclick = =>@hide(notify, sType)
   hide : (DOMNotify, sType)->
      oldHeight=DOMNotify.clientHeight + 12 + 3;
      DOMNotify.parentNode?.removeChild(DOMNotify)
      notifications=$a('.Notify_' + sType)
      if (notifications.length > 0)
         for ntf in notifications
            ntf.style.top = ntf.offsetTop - oldHeight + 'px';
inSide.__Register('Notifier', Notifier)
##
# LOAD INDICATOR
##
class LoadIndicator
   loadMessage : '<!--<progress>Загрузка...</progress>--><img src="static/loader.gif" height="32" width="32">'
   show : ->
      if not LoadIndicator::indicator?
         overlay=$c('div')
         overlay.style.height = window.innerHeight + 'px'
         overlay.style.width = window.innerWidth + 'px'
         overlay.style.position = 'fixed'
         overlay.style.top = '0px'
         overlay.style.left = '0px'
         overlay.style.background = 'rgba(0,0,0,0.5)'
         overlay.style.zIndex = '9999'
         overlay.id = 'Overlay'
         indicator=document.createElement('div')
         indicator.id = 'LoadIndicator'
         indicator.innerHTML = LoadIndicator::loadMessage
         overlay.appendChild(indicator)
         LoadIndicator::indicator = overlay
      document.body.appendChild(LoadIndicator::indicator)
   hide : ->
      document.body.removeChild(el) if el = document.getElementById('Overlay')
inSide.LoadIndicator = new LoadIndicator()
class Window
   windows : {}
   constructor : ->
      CONNECT 'inSide.WinMan.show', 'show', @
      CONNECT 'inSide.WinMan.close', '_close', @
   show : ({cls,title,app,args,options})->
      options={} if not options
      id=inSide.__nextID()
      overlay=$c('div')
      overlay.className = 'Overlay'
      overlay.setAttribute('data-id', id)
      overlay.style.height = window.innerHeight + 'px'
      overlay.style.width = window.innerWidth + 'px'
      overlay.style.position = 'fixed'
      overlay.style.top = '0px'
      overlay.style.left = '0px'
      overlay.style.background = 'rgba(0,0,0,0.5)'
      overlay.style.overflow = 'auto'
      overlay.style.zIndex = '9999'
      overlay.style.textAlign = 'center'

      resize=->
         overlay.style.height = window.innerHeight + 'px'
         overlay.style.width = window.innerWidth + 'px'
      window.addEventListener('resize', resize, false)

      if options.noclose
         close=''
      else
         close="""<img class="CloseWindow" style="float: right;cursor:pointer" class="point" height="16" src="#{inSideConf.img_dir}/Icons/cross.svg"/>"""
      overlay.innerHTML = """<div class="WINDOW #{cls}" id="WIN_#{id}" data-id="#{id}" draggable="true" style="text-align: left;display:inline-block">
                          <header class="WindowHead"><span style="padding-left: 20px;font-weight: bold">#{title}</span>
                          #{close}
                          </header><section class="Content"></section></div>
                          """
      a=@
      $s('.CloseWindow', overlay).onclick = ->a.close($d(@parentNode.parentNode, 'id'))
      args.__winId__ = id
      inSide.run(app, $s('.Content', overlay), args, ((h)->
         h.__winId__=id
         Window::windows[id] = h
         $s('body').appendChild(overlay)
      ))
      return id
   _close:({id})->@close(id)
   close : (sWindowId)->
      Window::windows[Number(sWindowId)].__destroy__()
      delete Window::windows[Number(sWindowId)]
      removeNodesBySelector """.Overlay[data-id="#{sWindowId}"]"""
inSide.__Register('WinMan', Window)
