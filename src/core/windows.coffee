class Notifier
    success:({head,body})->JAFW.Notifier.show(head,body,'Success')
    alert:({head,body})->JAFW.Notifier.show(head,body,'Alert',0)
    banner:({head,body})->JAFW.Notifier.show(head,body,'Banner')
    error:({body})->JAFW.Notifier.show('Ошибка',body,'Error')
    notify:({head,body})->JAFW.Notifier.show(head,body,'Notify')
    show:(sHead,sBody,sType='Notify',iTimeout=5000)->
        notify=$c('div')
        #TODO: сделать более гибким не прибегая к шаблонам
        notify.innerHTML="""<div class="NotifyHead">#{sHead}</div><div class="NotifyText">#{sBody}</div>""";
        notify.className='Notify Notify_'+sType;
        notifications=$a('.Notify_'+sType);
        height=0;
        for notification in notifications
            height+=notification.clientHeight+12+3;
        notify.style.top=60+height+'px';
        $s('body').appendChild(notify);
        if iTimeout
            notify.timeout=setTimeout((=>@hide(notify,sType)), iTimeout)
        else
            notify.onclick= =>@hide(notify,sType)
    hide:(DOMNotify,sType)->
        oldHeight=DOMNotify.clientHeight+12+3;
        DOMNotify.parentNode?.removeChild(DOMNotify)
        notifications=$a('.Notify_'+sType)
        if (notifications.length>0)
            for ntf in notifications
                ntf.style.top=ntf.offsetTop-oldHeight+'px';
JAFW.__Register('Notifier',Notifier)
##
# LOAD INDICATOR
##
class LoadIndicator
    loadMessage:'<!--<progress>Загрузка...</progress>--><img src="static/loader.gif" height="32" width="32">'
    show:->
        if not LoadIndicator::indicator?
            overlay=$c('div')
            overlay.style.height=window.innerHeight+'px'
            overlay.style.width=window.innerWidth+'px'
            overlay.style.position='fixed'
            overlay.style.top='0px'
            overlay.style.left='0px'
            overlay.style.background='rgba(0,0,0,0.5)'
            overlay.id='Overlay'
            indicator=document.createElement('div')
            indicator.id='LoadIndicator'
            indicator.innerHTML=LoadIndicator::loadMessage
            overlay.appendChild(indicator)
            LoadIndicator::indicator=overlay
        document.body.appendChild(LoadIndicator::indicator)
    hide:->
        document.body.removeChild(el) if el=document.getElementById('Overlay')
JAFW.LoadIndicator=new LoadIndicator()
class Window
    windows:{}
    constructor:->
        CONNECT 'CREATE_WINDOW','show',@
    show:({cls,title,app,args})->
        id=JAFW.__nextID()
        overlay=$c('div')
        overlay.className='Overlay'
        overlay.setAttribute('data-id',id)
        overlay.style.height=window.innerHeight+'px'
        overlay.style.width=window.innerWidth+'px'
        overlay.style.position='fixed'
        overlay.style.top='0px'
        overlay.style.left='0px'
        overlay.style.background='rgba(0,0,0,0.5)'
        overlay.style.overflow='auto'

        resize=->
            overlay.style.height=window.innerHeight+'px'
            overlay.style.width=window.innerWidth+'px'
        window.addEventListener('resize',resize,false)
        overlay.innerHTML="""<div class="WINDOW #{cls}" id="WIN_#{id}" data-id="#{id}" draggable="true">
                          <header class="WindowHead"><span style="padding-left: 20px;font-weight: bold">#{title}</span>
                          <img class="CloseWindow" style="float: right;cursor:pointer" class="point" height="16" src="#{JAFWConf.img_dir}/Icons/cross.svg"/>
                          </header><section class="Content"></section></div>
                          """
        a=@
        $s('.CloseWindow',overlay).onclick= ->a.close($d(@parentNode.parentNode,'id'))
        args.__winId__=id
        JAFW.run($s('.Content',overlay),app,args,((h)->Window::windows[id]=h))
        $s('body').appendChild(overlay)
        return id

    close:(sWindowId)->
        Window::windows[Number(sWindowId)].__destroy__()
        delete Window::windows[Number(sWindowId)]
        removeNodesBySelector """.Overlay[data-id="#{sWindowId}"]"""
JAFW.__Register('WinMan',Window)
class WindowOld
    windows:{}
    buttons:{
        'OK':'Ок',
        'CANCEL':'Отмена',
        'CLOSE':'Закрыть',
        'YES':'Да'
        'NO':'Нет'
        'ACCEPT':'Принять'
        'DECLINE':'Отклонить'
        'SAVE':'Сохранить'
    }
    show:(sWindowHtml,aButtonSet)->
        id=JAFW.nextID()
        window=$c('div')
        window.className='WINDOW'
        window.id="WIN_#{id}"
        window.style.position='absolute'
        buttonHtml='<div style="margin:auto"><table style="margin:auto"><tr>'
        aButtonSet=[] if not aButtonSet?
        for btn in aButtonSet
            buttonHtml+='<td><button id="WIN_'+id+'_'+btn+'">'+JAFW.Window::buttons[btn]+'</button></td>'
        buttonHtml+='</tr></table></div>'
        window.innerHTML=sWindowHtml+buttonHtml
        $s('body').appendChild(window)
        JAFW.Window::windows[id]={handlers:{}}
        for btn in aButtonSet
            ((btn)->$s('#WIN_'+id+'_'+btn).onclick=->
                if JAFW.Window::windows[id].handlers[btn]
                    JAFW.Window::windows[id].handlers[btn]()
                else
                    JAFW.Window::close(id)
            )(btn)
        id
    showModal:(sWindowHtml,aButtonSet,oParams)->
        id=JAFW.nextID()
        overlay=$c('div')
        overlay.id='Overlay_'+id
        overlay.className='Overlay'
        overlay.style.height=window.innerHeight+'px'
        overlay.style.width=window.innerWidth+'px'
        overlay.style.position='fixed'
        overlay.style.top='0px'
        overlay.style.left='0px'
        overlay.style.background='rgba(0,0,0,0.5)'
        overlay.style.overflow='auto'
        window.addEventListener('resize',
            ->
                overlay.style.height=window.innerHeight+'px'
                overlay.style.width=window.innerWidth+'px'
            ,false)
        buttonHtml='<div style="margin:auto"><table style="margin:auto"><tr>'
        aButtonSet=[] if not aButtonSet?
        for btn in aButtonSet
            buttonHtml+='<td><button id="WIN_'+id+'_'+btn+'">'+JAFW.Window::buttons[btn]+'</button></td>'
        buttonHtml+='</tr></table></div>'
        overlay.innerHTML="""<div class="WINDOW" id="WIN_#{id}">#{sWindowHtml+buttonHtml}</div>"""
        $s('body').appendChild(overlay)
        oParams={} if not oParams?
        if oParams.w
            $s('.WINDOW',overlay).style.width=oParams.w+'px';
        if oParams.h
            $s('.WINDOW',overlay).style.height=oParams.h+'px';
        $s('.WINDOW',overlay).style.margin='auto auto'

        JAFW.Window::windows[id]={handlers:{}}
        for btn in aButtonSet
            ((btn)->$s('#WIN_'+id+'_'+btn).onclick=->
                if JAFW.Window::windows[id].handlers[btn]
                    if JAFW.Window::windows[id].handlers[btn]()
                        JAFW.Window::close(id)
                else
                    JAFW.Window::close(id)
            )(btn)
        id
    close:(sWindowId)->
        removeNodesBySelector "#Overlay_#{sWindowId}"
        removeNodesBySelector "#WIN_#{sWindowId}"
        delete JAFW.Window::windows[sWindowId]
    setBtnHandler:(sWindowId,sBtnType,sHandler)->
        JAFW.Window::windows[sWindowId].handlers[sBtnType]=sHandler