RenderEngine=new jSmart()

assert=(exp,message='')->
    throw message if not exp

class self.JAFWCore
    _uid:0
    _mods:{}
    _tpls:{}
    ##
    # Генератор уникальных в пределах сессии ID
    ##
    __nextID:->JAFWCore::_uid++
    ##
    # Регистрация модулей
    ##
    __Register:(modName,module)->
        if modName in JAFWCore::_mods
            throw('Module already registered')

        JAFWCore::_mods[modName]=new module()
        Object.defineProperty(JAFWCore::,modName,{
            get:->JAFWCore::_mods[modName]
        })

##
# Загрузчик статических данных
##
class Staticdata
    _loaded:{}
    isLoaded:(root)->
        return if Staticdata::_loaded[root]? then true else false
    get:(root,callback)->
        if Staticdata::isLoaded(root.replace(':','_'))
            callback()
            return
        loadScripts=(scriptArray,callback)->
            scriptLink=scriptArray.shift()
            script = document.createElement("script");
            script.type = "text/javascript";
            script.src=scriptLink
            script.async=true
            script.onload=if scriptArray.length then (->loadScripts(scriptArray,callback)) else callback
            document.head.appendChild(script)
        storeMeta=(oResponse)->
            Staticdata::_loaded[root.replace(':','_')]=JSON.parse(oResponse.responseText)
            result=Staticdata::_loaded[root.replace(':','_')]
            for html of result.html
                RenderEngine.loadTemplate(root.replace(':','_')+':'+html,result.html[html])
            if result.js then loadScripts(result.js,callback) else callback()
        JAFW.Ajax.get('/jafwload/'+root,null,storeMeta,(->throw('Cannot load application data')))

##
# Среда запуска приложений
##
class AppEnvironment
    _registered:{}
    __Register:(appName)->
        throw('Application already registered') if appName in AppEnvironment::_registered
        class App
            __name__:appName
            handlers:{}
            runningHandlers:{}
            toString:->@__name__
            constructor:->
                CONNECT 'jafw.Apps.'+@__name__+'.destroy','__destroy__',@
            __destroy__:->
                for hid,handler of @runningHandlers
                    handler.__destroy__()
            HANDLER:(name,body)->
                a=@
                body.put=(selector,blockName,args)->a.put.call(a,selector,blockName,args, @__id__)
                body.__app__=appName
                if not body.preRender?
                    body.preRender=(r,args)->r(args)
                body.__destroy__=()->
                    #TODO: удалять из списка потомков
                    DISCONNECT('*','*',@)
                    # Пользовательский деструктор
                    if @destroy?
                        @destroy()
                    return if not a.runningHandlers[@__id__]?
                    # Вызов деструкторов потомков
                    for c in a.runningHandlers[@__id__].__children__
                        c.__destroy__(true)
                    if @__container__?.innerHTML?
                        @__container__.innerHTML=''
                    delete a.runningHandlers[@__id__]
                AppEnvironment::_registered[appName].handlers[name]=->
                    for p of body
                        @[p]=body[p]
                    undefined
            put:(selector,blockName,args,parentHid=null)->
                args={} if not args

                if typeof(selector)==typeof({})
                    container=selector
                else
                    container=if selector then $s(selector) else null

                hid=JAFW.__nextID()
                @runningHandlers[hid]=new AppEnvironment::_registered[appName].handlers[blockName](selector)
                handler=@runningHandlers[hid]
                handler.__name__=blockName
                handler.__id__=hid
                handler.__parent__=parentHid
                handler.__children__=[]
                handler.__container__=container
                handler.toString=->@__app__+":"+@__name__
                if parentHid of @runningHandlers
                    @runningHandlers[parentHid].__children__.push(handler)
                # Обертки событий DOM для обработчика
                installDOMWrappers(handler,container)
                init=(data)=>
                    for p of data
                        args[p] = data[p]
                    if container
                        if Staticdata::_loaded[@__name__]?.html[blockName]?
                            args.config=JAFWConf
                            css=if Staticdata::_loaded[@__name__]?.css[blockName]? then Staticdata::_loaded[@__name__].css[blockName] else ''
                            style='<style scoped>'+css+'</style>'
                            container.innerHTML=style+RenderEngine.render(@__name__+':'+blockName,args)

                    handler.init(container,args)
                #AppEnvironment::_registered[appName].running.push(handler)
                handler.__reload__= ((init,args)->->handler.preRender(init,args))(init,args)
                handler.preRender(init,args)
                return handler


        AppEnvironment::_registered[appName]=new App()
        Object.defineProperty(AppEnvironment::,appName,{
            get:->AppEnvironment::_registered[appName]
        })

    load:(appName,callback)->
        JAFW.Static.get(appName.replace('.','/'),callback)
##
# РАБОТА С URL: кодирование/декодирование объектов в/из строки URL
##
class URL
    # Разбор объекта и сериализация его в параметры URL
    # oSubObject - Объект для сериализации
    # sPrefix - Префикс сериализации. Помещается перед разобранной строкой.
    # Если префикс не пустой, сериализованный объект заключается в [квадратные скобки]
    encode:(oSubObject,sPrefix)->
        # Если объект - строка, сериализация не нужна
        return oSubObject if typeof oSubObject == typeof ''
        encoded=[]
        for keyIndex,subObject of oSubObject
            # Вычисление имени ключа с учетом префикса.
            keyName=if sPrefix then "#{sPrefix}[#{encodeURIComponent(keyIndex)}]" else encodeURIComponent(keyIndex)
            # Разбор узла дерева. Если значение примитивное, запоминаем строку key=val, иначе рекурсивно спускаемся по дереву
            encoded.push if typeof subObject != typeof {} then "#{keyName}=#{encodeURIComponent(subObject)}" else URL::encode(subObject,keyName)
        encoded.join('&')
    # Получение объекта из строки URL
    # sUrlStr - строка URL. Если sUrlStr не определена, берется текущая URL строка браузера.
    decode:(sUrlStr)->
        sUrlStr = self.location.href.slice(self.location.href.indexOf('?') + 1) if sUrlStr==undefined
        hashes=sUrlStr.split('&')
        vars={}
        # Разбор ключа, создание дерева объекта
        # sKey - ключ URL
        # oObject - объект, в который записывается разобранные значения
        # vValue - значение ключа, которое будет помещено в узел oObject, соответствующий ключу sKey
        parseKey=(sKey,oObject,vValue)->
            # Выбор следующего ключа для создания
            key=sKey.substr(0,sKey.indexOf('['))
            # Если sKey - не массив, записываем значение в oObject
            if !key
                oObject[sKey]=vValue
                return
            # Создаем узел key в объекте oObject
            oObject[key]={} if !oObject[key]?
            # Избавляемся от ] в отсавшейся неразобранной строке и продолжаем рекурсивную обработку
            unparsed=sKey.substr(sKey.indexOf('[')+1)
            parseKey(unparsed.substr(0,unparsed.indexOf(']'))+unparsed.substr(unparsed.indexOf(']')+1),oObject[key],vValue)
        # Разбор каждого хэша key=val
        for hash in hashes
            [key,val] = decodeURIComponent(hash).split('=');
            parseKey(key,vars,val)
        vars
##
# АСИНХРОННАЯ ПЕРЕДАЧА ДАННЫХ
##
class Ajax
    # Отправка GET-запроса на сервер
    # sUrl - URL, на который отправится запрос
    # oData - объект данных
    # fSuccess/fError - обработчики успешного/ошибочного запроса
    get:(sUrl,oData,fSuccess,fError)->Ajax::request('GET',sUrl,oData,fSuccess,fError)
    # Отправка POST-запроса на сервер
    # sUrl - URL, на который отправится запрос
    # oData - объект данных
    # fSuccess/fError - обработчики успешного/ошибочного запроса
    post:(sUrl,oData,fSuccess,fError)->Ajax::request('POST',sUrl,oData,fSuccess,fError)
    # Отправка запроса на сервер
    # sMethod - тип запроса (GET/POST)
    # sUrl - URL, на который отправится запрос
    # oData - объект данных
    # fSuccess/fError - обработчики успешного/ошибочного запроса
    request:(sMethod,sUrl,oData,fSuccess,fError)->
        request=new XMLHttpRequest()
        request.onreadystatechange=->
            if request.readyState == 4
                # Если не произошло ошибок на протокольном уровне, выполняем fSuccess, иначе fError
                handler=if request.status==200 then fSuccess else fError
                handler?(request)
        requestData=URL::encode oData
        # Если метод - GET, кладем данные с строку запроса
        if sMethod=='GET'
            sUrl+="?#{requestData}"
            requestData=null
        # Выполнение асинхронного запроса
        request.open(sMethod,sUrl,true);
        # Заголовок для POST
        request.setRequestHeader("Content-type", "application/x-www-form-urlencoded") if sMethod=='POST'
        request.send(requestData)

###
    СИГНАЛЫ

    Именование:
        sigName ::= [typeDescriptor] [a-zA-Z._]+
        typeDescriptor ::= [=@]{,1}
    Типы:
    sigName - простой сигнал, отправляется на локальные объекты, подписка является постоянной
    =sigName - временный сигнал. отправляется на локальные объекты, подписка уничтожается после вызова
    @sigName - глобальный сигнал - пересылается на локальные объекты и на сервер
    * - любой сигнал
###
signalModifiers=['@','=','*']
parseSignal=(sSignal)->
    [signal,emitter]=sSignal.split(':')
    name=signal.replace(new RegExp('['+signalModifiers.join('')+']'),'')
    modifier=if signal[0] in signalModifiers then signal[0] else ''
    return {name,emitter,modifier}
validateSignal=(sSignal)->
    if sSignal!='*'
        assert(sSignal.match('^['+signalModifiers.join('')+']?[a-zA-Z][a-zA-Z_.]*$'),'Bad signal name: '+sSignal)
# Таблица соединений сигналов и объектов
__connectionTable={}
addConnection=(sSignal,sSlot,oReceiver,fSlot)->
    objectName=oReceiver.toString()
    __connectionTable[sSignal]={} if not __connectionTable[sSignal]?
    __connectionTable[sSignal][objectName]={instance:oReceiver,slots:{}} if not __connectionTable[sSignal][objectName]?
    if (fSlot)
        __connectionTable[sSignal][objectName].slots[sSlot]=fSlot
    else
        __connectionTable[sSignal][objectName].slots[sSlot]=oReceiver[sSlot]
    sSlot
removeConnection=(sSignal,sSlot,oReceiver)->
    objectName=oReceiver.toString()
    if sSignal=='*'
        for sig of __connectionTable
            delete __connectionTable[sig][objectName] if __connectionTable[sig]?[objectName]?
        return

    if __connectionTable[sSignal]?[objectName]?.slots[sSlot]
        delete __connectionTable[sSignal][objectName].slots[sSlot]
    else
        return
    if Object.keys(__connectionTable[sSignal][objectName].slots).length==0
        delete __connectionTable[sSignal][objectName]
        if Object.keys(__connectionTable[sSignal]).length==0
            delete __connectionTable[sSignal]
invoke=(sSignal,oData,emitResult=false)->
    # Глобальная рассылка (не только на клиент, но и на сервер и дочерние окна)
    if sSignal[0]=='@'
        sSignal=sSignal[1..]
        api.call sSignal, oData,(oResponseSignal)->
            if oResponseSignal
                EMIT(oResponseSignal.name,oResponseSignal.data)
    # TODO: отправлять на дочерние окна
    #[signal,uid]=sSignal.split(':')
    sigData=parseSignal(sSignal)
    temporary=(sigData.modifier=='=')
    invokeSlots=(connectionList)->
        for appName,connectionInfo of connectionList
            for slotName,slot of connectionInfo.slots
                res=slot.call(connectionInfo.instance,oData,sigData.emitter)
                if sigData.emitter and emitResult and res isnt null
                    EMIT '='+sigData.name,res,sigData.emitter
                #Удаляем временные сигналы
                if temporary
                    removeConnection('='+sigData.name+(if sigData.emitter then ':'+sigData.emitter else ''),slotName,connectionInfo.instance)
        return
    # Локальная рассылка
    if __connectionTable[sSignal]
        invokeSlots(__connectionTable[sSignal])
    else if __connectionTable[sigData.modifier+sigData.name]
        invokeSlots(__connectionTable[sigData.modifier+sigData.name])

# Удалить подписку на сигнал
# sSignal - название сигнала
# sSlot - название обработчика сигнала
# oReceiver - объект, для которого выполнить отключение
self.DISCONNECT=(sSignal,sSlot,oReceiver,UID=null)->
    validateSignal(sSignal)
    sSignal+=(':'+UID) if UID
    removeConnection(sSignal,sSlot,oReceiver)
# Подписать объект на сигнал. Возвращает название обработчика, которое можно использовать для отключение
# sSignal - название сигнала
# sSlot - название обработчика сигнала, содержащегося в oReceiver. Если sSlot - функция, генерируется уникальный ID
# oReceiver - объект, для которого выполнить подключение. oReceiver должен иметь свойство toString, возвращающее уникальное имя объекта
self.CONNECT=(sSignal,sSlot,oReceiver,UID=null)->
    validateSignal(sSignal)
    sSignal+=(':'+UID) if UID
    # Если sSlot - функция, генерируем UID и подписываем объект на анонимную функцию
    if (typeof sSlot == typeof(->))
        fSlot=sSlot
        sSlot=JAFW.__nextID()
    else
        throw "No such slot: #{sSlot}" if not oReceiver[sSlot]?
    addConnection(sSignal,sSlot,oReceiver,fSlot)
# Порождение сигнала
# sSignal - название сигнала
# oArgs - параметры сигнала
# oSender - отправитель
self.EMIT=(sSignal,oArgs,oSender=null,emitResult=false)->
    validateSignal(sSignal)
    sSignal=(sSignal+':'+(if oSender.__id__? then oSender.__id__ else oSender.toString())) if oSender
    invoke(sSignal,oArgs,emitResult)
self.EMIT_AND_WAIT=(oSender,sSignal,oArgs,sSlot)->
    sSignal.replace('=','')
    validateSignal(sSignal)
    CONNECT('='+sSignal,sSlot,oSender,oSender.__id__)
    EMIT(sSignal,oArgs,oSender,true)

class Signal
    constructor:(@context,@name,@maxHandlers=-1)->@
    setMaxHandlers:(@maxHandlers=-1)->@
    tunnel:(@tunnelName)->@
    emit:(args)->EMIT(@name,args);return @
    emitAndWait:(args)->EMIT_AND_WAIT(@context,@name,args,@name+'=');return @
    _serialize:()->
class SigHandler
    constructor:(@context,@sigName,@handler)->
    _deserialize:()->

# Вид URL: #/appName:view/urlencode(param1)/...
# Запуск взаимоисключающих приложений в один контейнер
class Launcher
    constructor:()->
        CONNECT('LAUNCHER_PUSH','push',@)
        CONNECT('LAUNCHER_REPLACE','repl',@)
        CONNECT('LAUNCHER_BACK','back',@)
        @sel='body'
        # обработчик изменения хеша в адресной строке
        self.onhashchange= (e)=>
            #TODO: call destroy for running views
            [app,args]=e.newURL.split('#')[1].substr(1).split('/')
            JAFW.run(@sel,app,JAFW.Url.decode(args))
        self.onpopstate=(e)=>
            @sel=e.state
    back:->
        self.history.back()
    push:({cont,app,args})->
        self.history.pushState(cont,null,"/#/#{app}/#{JAFW.Url.encode(args)}")
        @sel=cont
        self.onhashchange({newURL:"/#/#{app}/#{JAFW.Url.encode(args)}"})
    repl:({cont,app,args})->
        self.history.pushState(cont,null,"/#/#{app}/#{JAFW.Url.encode(args)}")
        @sel=cont
        self.onhashchange({newURL:"/#/#{app}/#{JAFW.Url.encode(args)}"})

JAFWCore::__Register('Url',URL)
JAFWCore::__Register('Ajax',Ajax)
JAFWCore::__Register('Static',Staticdata)
JAFWCore::__Register('Signal',Signal)
JAFWCore::__Register('Apps',AppEnvironment)
JAFWCore::__Register('Launcher',Launcher)
self.JAFW=new JAFWCore()

##
# Запуск блока приложения
##
currentApp=null
JAFW.run=(selector,appSignature,args)->
    [ns,name]=appSignature.split('::')
    [ns,name]=['',ns] if not name
    [appName,blockName]=name.split(':')
    appName=if ns then ns+':'+appName else appName
    appAccess=appName.replace(':','_')
    _run=->
        #if currentApp
        #    currentApp.__destroy__()
        currentApp=JAFW.Apps[appAccess].put(selector,blockName,args)
    if appAccess not of JAFW.Apps._registered
        JAFW.Apps.__Register(appAccess)
        JAFW.Apps.load appName,->
            _run()
    else
        _run()
