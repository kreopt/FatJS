class JAFW.Notifier
    show:(sHead,sBody)->
        notify=$c('div')
        #TODO: сделать более гибким не прибегая к шаблонам
        notify.innerHTML="""<div class="NotifyHead">#{sHead}</div><div class="NotifyText">#{sBody}</div>""";
        notify.className='Notify';
        notifications=$a('.Notify');
        height=0;
        for notification in notifications
            height+=notification.clientHeight+12+3;
        notify.style.top=60+height+'px';
        $s('body').appendChild(notify);
        notify.timeout=setTimeout ->
            oldHeight=notify.clientHeight+12+3;
            notify.parentNode?.removeChild(notify)
            notifications=$a('.Notify')
            if (notifications.length>0)
                for ntf in notifications
                    ntf.style.top=ntf.offsetTop-oldHeight+'px';
        ,5000;
    toString:->'Notifier'
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
class JAFW.Window
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