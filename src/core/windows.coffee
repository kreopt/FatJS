class Notifier
   success : ({head,body})->inSide.Notifier.show(head, body, 'success')
   error : ({body})->inSide.Notifier.show('Ошибка', body, 'danger')
   notify : ({head,body})->inSide.Notifier.show(head, body, 'info')
   show : (sHead, sBody, sType = 'info', iTimeout = 5000)->
      sHead='' if not sHead
      notify=$c('div')
      notify.className="Notify alert alert-#{sType}"
      notify.innerHTML = """<strong>#{sHead}</strong> #{sBody}""";
      notifications=$a('.Notify' );
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
      $(DOMNotify).fadeOut(500)
      setTimeout(((DOMNotify)->->
         $(DOMNotify).remove()
         notifications=$a('.Notify' )
         if (notifications.length > 0)
            for ntf in notifications
               ntf.style.top = ntf.offsetTop - oldHeight + 'px';
      )(DOMNotify), 500)

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
         indicator.innerHTML = @loadMessage
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
      overlay.className = """modal fade #{cls} WMOverlay"""
      overlay.id='WMModal'
      $attr(overlay,'role','dialog')
      $attr(overlay,'aria-hidden','true')
      $d(overlay,'id',id)

      dialog="""
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
      """ +
      (if options.noclose then "" else """<button type="button" class="close" data-dismiss="modal" data-id="#{id}" aria-hidden="true">&times;</button>""") +
      """
              <h4 class="modal-title">#{title}</h4>
            </div>
            <div class="modal-body WMContent">
            </div>
          </div><!-- /.modal-content -->
        </div><!-- /.modal-dialog -->
      """

      overlay.innerHTML = dialog
      a=@
      $s('.CloseWindow', overlay).onclick = ->a.close($d(@, 'id'))
      args.__winId__ = id
      inSide.run(app, $s('.WMContent', overlay), args, ((h)->
         h.__winId__=id
         Window::windows[id] = h
         $s('body').appendChild(overlay)
         $(overlay).modal('show')
         $(overlay).on 'hidden.bs.modal', ->
            $(this).remove()
      ))
      return id
   _close:({id})->@close(id)
   close : (sWindowId)->
      Window::windows[Number(sWindowId)].__destroy__()
      delete Window::windows[Number(sWindowId)]
      removeClass($s('body'), 'modal-open')
      $('#WMModal').modal('hide')
inSide.__Register('WinMan', Window)
