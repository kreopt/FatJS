#TODO: переписать на HistoryAPI
# Запуск взаимоисключающих приложений в один контейнер
class JAFW.Launcher
    # Конструктор принимает ID контейнера, в который будут рендериться приложения
    constructor:(sContainerId,hashChange=true)->
        @container=sContainerId
        @containerDOM=$s('#'+sContainerId)
        # currentApp - текущее выполняемое приложение
        @currentApp=null
        # Как только запускаемое приложение готово, выполняем обработчик события старта
        CONNECT 'APP_READY','onAppStart',@
        # stateStack - стек состояний запущенных приложений. При запуске другого приложения,
        # текущее может не закрываться, а сохранить свое состояние для последующего восстановления
        @stateStack=[]
        # evented указывает на то, каким образом был изменен хеш. если false, значит вручную
        @evented=1
        # свойство доступа к вершине ыстека состояний
        Object.defineProperty(@,'stateTop',{get:->@stateStack[@stateStack.length-1]})
        # Менять ли хеш при запуске приложения?
        @hashChange=hashChange
        if hashChange
            # обработчик изменения хеша в адресной строке
            window.onhashchange= =>
                # срабатывает только тогда, когда evented==true
                if @evented
                    # Если изменили хеш непосредственно в адресной строке, уничтожаем текущее приложение
                    @currentApp?.__destroy()
                    # Запускаем приложение по его имени
                    appName=@getAppName()
                    # Если возвращаемся на предыдущее состояние - восстанавливаем его
                    res=false
                    res=@pop() while @stateStack.length>1 and @stateTop.name!=appName
                    res=false if @stateTop.name!=appName
                    if not res
                        @run appName
                # Восстанавливаем состояние evented на true(по-умолчанию)
                @evented=1
    # Получение имени приложения и его параметров из строки URL
    # Возвращает имя приложения. Параметры записываются в @params
    getAppName:->
        hash=window.location.hash.substr(1)
        if hash.indexOf('?')!=-1
            appName=hash.slice(0,hash.indexOf('?'))
            params=hash.slice(hash.indexOf('?')+1)
        else
            appName=hash
            params=''
        @params=if params then JAFW.URL::decode(params) else ''
        appName
    # Обработчик события готовности приложения. Записывает в currentApp только что запущенное приложение
    # oMessage имеет формат {containerId,appName,appUID}
    onAppStart:(oMessage)=>
        if oMessage.container==@container
            @currentApp=JAFW.running[oMessage.name][oMessage.uid]
    # Запуск приложения с очисткой стека состояний.
    # sName - имя приложения
    # oParams - параметры в JSON
    run:(sName,oParams)->
        # уничтожаем текущее приложение
        @currentApp?.__destroy()
        @params=if oParams then oParams else @params
        # сбрасываем флаг evented, чтобы не вызывался обработчик изменения хеша
        if @hashChange
            hash=sName+(if @params then '?'+JAFW.URL::encode(@params) else '')
            if ('#'+hash)!=window.location.hash
                @evented=0
                window.location.hash=hash
        # запуск приложения в контейнер ланчера
        RUN sName,@container,(uid)=>
            @currentApp=JAFW.running[sName][uid]
            # После запуска стек содержит состояние только текущего приложения
            @stateStack=[{name:sName,app:@currentApp,cont:@containerDOM}]
    # Запуск приложения с занесением ткущего в стек.
    # sName - имя приложения
    # oParams - параметры в JSON
    push:(sName,oParams)->
        stateCont=@containerDOM
        newCont=@containerDOM.cloneNode(false)
        @containerDOM.parentNode.replaceChild(newCont,stateCont)
        @containerDOM=newCont
        # сбрасываем флаг evented, чтобы не вызывался обработчик изменения хеша
        @params=if oParams then oParams else @params
        if @hashChange
            hash=sName+(if @params then '?'+JAFW.URL::encode(@params) else '')
            if ('#'+hash)!=window.location.hash
                @evented=0
                window.location.hash=hash
            ((stateCont)=>RUN sName,@container,(uid)=>
                @currentApp=JAFW.running[sName][uid]
                # Дополняем стек состоянием только что запущенного приложения
                @stateStack.push({name:sName,app:@currentApp,cont:stateCont}))(stateCont)
    # Возврат к предыдущему приложению
    pop:()->
        # Если стек состоит только из одного состояния приложения, возвращатсья некуда
        return false if @stateStack.length<2
        # Восстанавливаем предыдущее состояние контейнера
        @containerDOM.parentNode.replaceChild(@stateTop.cont,@containerDOM)
        @containerDOM=@stateTop.cont
        # Выталкиваем "ненужное" состояние из стека
        @stateStack.pop()
        @evented=0
        if @hashChange
            window.location.hash=@stateTop.name
        true