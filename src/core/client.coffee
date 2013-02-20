# CLIENT SIDE

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
                JAFW.RenderEngine.loadTemplate(root.replace(':','_')+':'+html,result.html[html])
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
                body.__destroy__=(calledByParent=false)->
                    # удаляем обработчик из списка потомков родителя
                    if @__parent__ and (not calledByParent)
                        children=a.runningHandlers[@__parent__].__children__
                        for child,childIndex in children
                            if child.__id__==@__id__
                                a.runningHandlers[@__parent__].__children__.splice(childIndex,1)
                                break
                    DISCONNECT('*','*',@)
                    # Пользовательский деструктор
                    @destroy() if @destroy?
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
                            container.innerHTML=style+JAFW.RenderEngine.render(@__name__+':'+blockName,args)

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
        requestData=JAFW.Url.encode oData
        # Если метод - GET, кладем данные с строку запроса
        if sMethod=='GET'
            sUrl+="?#{requestData}"
            requestData=null
        # Выполнение асинхронного запроса
        request.open(sMethod,sUrl,true);
        # Заголовок для POST
        request.setRequestHeader("Content-type", "application/x-www-form-urlencoded") if sMethod=='POST'
        request.send(requestData)

# Вид URL: #/appName:view/urlencode(param1)/...
# Запуск взаимоисключающих приложений в один контейнер
class Launcher
    toString:->'appLauncher'
    constructor:()->
        CONNECT('LAUNCHER_PUSH','push',@)
        CONNECT('LAUNCHER_REPLACE','repl',@)
        CONNECT('LAUNCHER_BACK','back',@)
        CONNECT('LAUNCHER_START','start',@)
        @sel='#jafw_container'
        @defaultSelector='#jafw_container'
        @defaultApp='Main:index'
        @containerApps={}
        @currentView=null
        @storedStates={}
        # обработчик изменения хеша в адресной строке
        self.onhashchange= (e)=>
            @sel=@defaultSelector if not @sel
            [app,args]=e.newURL.split('#')[1].substr(1).split('/')
            app=@defaultApp if not app
            [appName,view]=app.split(':')
            @containerApps[@sel].__destroy__() if @containerApps[@sel]? and appName!= @containerApps[@sel].__app__
            storeCA= (a)=>
                @currentView=a
                # Восстанавливаем последнее состояние представления
                name=a.__app__+':'+a.__name__
                if @storedStates[name]?
                    @currentView?.__restore__?(@storedStates[name])
                    delete @storedStates[name]
                if (not @containerApps[@sel]?) or (@containerApps[@sel].__app__!= a.__app__)
                    @containerApps[@sel]=a
            # сохраняем последнее состояние представления, если есть функция сохранения
            @storedStates[@currentView.__app__+':'+@currentView.__name__]=@currentView.__store__() if @currentView?.__store__?
            JAFW.run(@sel,app,JAFW.Url.decode(args),storeCA)
        self.onpopstate=(e)=>
            @sel=e.state
    start:({app,selector,args})->
       args={} if not args
       @defaultApp=app
       @defaultContainer=selector
       [appName,view]=app.split(':')
       @containerApps[selector].__destroy__() if @containerApps[selector]? and appName!= @containerApps[selector].__app__
       storeCA= (a)=>
          @currentView=a
          @containerApps[selector]=a
          # загружаем приложение, указанное в адресной строке
          [app,args]=window.location.hash.split('#')[1].substr(1).split('/')
          return if not app
          @push({app,cont:@defaultContainer,args:JAFW.Url.decode(args)})
       # сохраняем последнее состояние представления, если есть функция сохранения
       JAFW.run(@sel,app,args,storeCA)
    back:->
        self.history.back()
    push:({cont,app,args})->
        self.history.pushState?(cont,(if @currentView?.__printable__? then @currentView.__printable__ else null),"/#/#{app}/#{JAFW.Url.encode(args)}")
        @sel=cont
        self.onhashchange({newURL:"/#/#{app}/#{JAFW.Url.encode(args)}"})
    repl:({cont,app,args})->
        self.history.pushState?(cont,(if @currentView?.__printable__? then @currentView.__printable__ else null),"/#/#{app}/#{JAFW.Url.encode(args)}")
        @sel=cont
        self.onhashchange({newURL:"/#/#{app}/#{JAFW.Url.encode(args)}"})
##
# Запуск блока приложения
##
containerApps=null
JAFW.run=(selector,appSignature,args,onload)->
    [ns,name]=appSignature.split('::')
    [ns,name]=['',ns] if not name
    [appName,blockName]=name.split(':')
    appName=if ns then ns+':'+appName else appName
    appAccess=appName.replace(':','_')
    _run=->
        #if currentApp
        #    currentApp.__destroy__()
        JAFW.Apps[appAccess].put(selector,blockName,args)
    if appAccess not of JAFW.Apps._registered
        JAFW.Apps.__Register(appAccess)
        JAFW.Apps.load appName,->
            a=_run()
            onload(a) if onload?
    else
        a=_run()
        onload(a) if onload?

JAFW.__Register('Ajax',Ajax)
JAFW.__Register('Static',Staticdata)
JAFW.__Register('Apps',AppEnvironment)
JAFW.__Register('Launcher',Launcher)