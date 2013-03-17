# CLIENT SIDE
##
# Среда запуска приложений
##
#TODO: Избавиться от избыточности, вводимой различием классов AppEnvironment и App
class AppEnvironment
    _styles:{}
    _registered:{}
    _inits:{}
    _putQueue:[]
    _busy:false
    _running:{}
    _dirty:false
    _garbageCollect:(appClass)->
       if AppEnvironment::_dirty
          for appId,app of AppEnvironment::_running
             continue if app.__container__ is null
             if not app.__container__.parentNode
                console.log('Garbage collector destroying app: '+app.__name__+' at container '+appId)
                app.__destroy__()
                delete AppEnvironment::_running[appId]
                delete appClass.runningHandlers[appId]
          AppEnvironment::_dirty=false
    __Register:(appName)->
        throw('Application already registered') if appName in AppEnvironment::_registered
        class App
            __name__:appName
            handlers:{}
            handlersProp:{}
            runningHandlers:{}
            toString:->@__name__
            constructor:->
                CONNECT 'inSide.Apps.'+@__name__+'.destroy','__destroy__',@
            __destroy__:->
                for hid,handler of @runningHandlers
                    handler.__destroy__()
            HANDLER:(name,body)->
                a=@
                body.__app__=appName
                body.run=(selector,appSignature,args,onload)->
                   JAFW.run(selector,appSignature,args,onload,@__id__)
                body.put=(selector,blockName,args,onload)->
                  a.put.call(a,selector,blockName,args, @__id__,onload)
                body.__destroy__=(calledByParent=false)->
                    # удаляем обработчик из списка потомков родителя
                    if @__parent__ and (not calledByParent) and a.runningHandlers[@__parent__]
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
                    delete AppEnvironment::_running[@__id__]
                body.kill=(selector,app)->
                   if AppEnvironment::_running[selector]?
                     @__destroy__.call(AppEnvironment::_running[selector])

                body.preRender=((r,args)->r(args)) if not body.preRender?

                AppEnvironment::_registered[appName].handlersProp[name]=body
                AppEnvironment::_registered[appName].handlers[name]=->
                    body=AppEnvironment::_registered[appName].handlersProp[name]
                    for p of body
                        @[p]=body[p]
                    for p,v of body.__super__
                       if typeof(body.__super__[p])==typeof(->)
                          body.__super__[p]=v.bind(@)
                    undefined
                if body.__extends__?
                   [ns,nm]=body.__extends__.split('::')
                   [ns,nm]=['',ns] if not nm
                   [eappName,eblockName]=nm.split(':')
                   eappName=if ns then ns+':'+eappName else eappName
                   eappAccess=eappName.replace(':','_')
                   if eappAccess not of JAFW.Apps._registered
                      JAFW.Apps.__Register(eappAccess)
                   AppEnvironment::startView eappAccess,eblockName,{},null,=>
                      extendable=AppEnvironment::_registered[appName].handlersProp[name]
                      extendable.__super__=new AppEnvironment::_registered[eappAccess].handlers[eblockName]()
                      for prop,val of AppEnvironment::_registered[eappAccess].handlersProp[eblockName]
                         extendable[prop]=val if not extendable[prop]?
                      AppEnvironment::_inits[appName+':'+name](AppEnvironment::_registered[appName].handlers[name])
                else
                   AppEnvironment::_inits[appName+':'+name](AppEnvironment::_registered[appName].handlers[name])
            put:(selector,blockName,args,parentHid=null,onload=null)->
               if AppEnvironment::_busy==true
                  AppEnvironment::_putQueue.push([appName,selector,blockName,args,parentHid,onload])
                  return
               AppEnvironment::_garbageCollect(@)
               AppEnvironment::_busy=true
               AppEnvironment::startView @__name__,blockName,args,selector,=>
                   args={} if not args

                   if typeof(selector)==typeof({})
                       container=selector
                   else
                       container=if selector then $s(selector) else null

                   hid=JAFW.__nextID()
                   console.log("""#{@__name__}:#{blockName}""")
                   @runningHandlers[hid]=new AppEnvironment::_registered[@__name__].handlers[blockName](selector)
                   handler=@runningHandlers[hid]

                   handler.__name__=blockName
                   handler.__id__=hid
                   handler.__parent__=parentHid
                   handler.__children__=[]
                   handler.__container__=container
                   handler.__reload__= ((init,args)->->handler.preRender(init,args))(init,args)

                   AppEnvironment::_running[selector]=handler
                   handler.toString=->@__app__+":"+@__name__
                   if parentHid of @runningHandlers
                       @runningHandlers[parentHid].__children__.push(handler)
                   # Обертки событий DOM для обработчика
                   installDOMWrappers(handler,container)

                   loadStyle=(name,next)=>
                      success=(req)=>
                         AppEnvironment::_styles[name]=if req.responseText.replace(new RegExp("\\s"),'')!='' then """<style scoped="scoped">#{req.responseText}</style>""" else ""
                         next()
                      error=->success({responseText:''})
                      if not AppEnvironment::_styles[name]?
                         path=name.split(':').join('/')
                         Ajax::get("""#{JAFWConf.app_dir}/#{path}.css""",'',success,error)
                      else
                         next()
                   loadTemplate=(name,next)=>
                      if not JAFW.RenderEngine._tpl[name]?
                         success=(tpl)=>
                            JAFW.RenderEngine.loadTemplate(name,tpl.responseText)
                            next()
                         error=()=>success({responseText:''})
                         path=name.split(':').join('/')
                         Ajax::get("""#{JAFWConf.app_dir}/#{path}.jade""",'',success,error)
                      else
                         next()

                   initApp=(handler,args,onload)->
                      handler.init(handler.__container__,args)
                      onload?(handler)
                   render=(style,view)->
                      handler.__container__.innerHTML=style+view
                      AppEnvironment::_dirty=true
                   init=(data)=>
                      for p of data
                         args[p] = data[p]
                      if handler.__container__
                         args.config=JAFWConf
                         styleName=@__name__+':'+blockName
                         view=JAFW.RenderEngine.render(@__name__+':'+blockName,args)

                         #TODO: inheritance chain
                         if handler.__extends__?
                            styleName=handler.__extends__ if AppEnvironment::_styles[styleName]==''
                            loadStyle styleName, =>
                               if view == ''
                                  loadTemplate handler.__extends__,=>
                                     view=JAFW.RenderEngine.render(handler.__extends__,args)
                                     render(AppEnvironment::_styles[styleName],view)
                                     initApp(handler,args,onload)
                               else
                                  render(AppEnvironment::_styles[styleName],view)
                                  initApp(handler,args,onload)
                         else
                            render(AppEnvironment::_styles[styleName],view)
                            initApp(handler,args,onload)
                      else
                         initApp(handler,args,onload)
                   loadStyle (@__name__+':'+blockName),=>
                      loadTemplate (@__name__+':'+blockName),=>
                         AppEnvironment::_busy=false
                         if AppEnvironment::_putQueue.length
                            nextargs=AppEnvironment::_putQueue.shift()
                            @put.apply(AppEnvironment::_registered[nextargs.shift()],nextargs)
                         handler.preRender(init,args)
                   return handler

        AppEnvironment::_registered[appName]=new App()
        Object.defineProperty(AppEnvironment::,appName,{
        get:->AppEnvironment::_registered[appName]
        })
    startView:(appName,blockName,args,container,onLoad)->
       if AppEnvironment::_registered[appName]?.handlers[blockName]?
          onLoad(container,args)
       else
          AppEnvironment::_inits[appName+':'+blockName]=->
             onLoad(container,args)
          script = document.createElement("script");
          script.type = "text/javascript";
          script.src="""#{JAFWConf.app_dir}/#{appName}/#{blockName}.js"""
          #script.async=true
          document.head.appendChild(script)


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
           if requestData
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
            hash=e.newURL.split('#')
            if hash[1]
               [app,args]=hash[1].substr(1).split('/')
            else
               app=@defaultApp
               args=""
            [appName,view]=app.split(':')
            if @containerApps[@sel]?
               return if appName== @containerApps[@sel].__app__ and view==@containerApps[@sel].__name__
               @containerApps[@sel].__destroy__()
            storeCA= (a)=>
                @currentView=a
                # Восстанавливаем последнее состояние представления
                name=a.__app__+':'+a.__name__
                if @storedStates[name]?
                    @currentView?.__restore__?(@storedStates[name])
                    delete @storedStates[name]
                if (not @containerApps[@sel]?) or (@containerApps[@sel].__app__!= a.__app__ or @containerApps[@sel].__name__!= a.__name__)
                    @containerApps[@sel]=a
            # сохраняем последнее состояние представления, если есть функция сохранения
            @storedStates[@currentView.__app__+':'+@currentView.__name__]=@currentView.__store__() if @currentView?.__store__?
            JAFW.run(@sel,app,JAFW.Url.decode(args),storeCA)
        self.onpopstate=(e)=>
            @sel=e.state
    start:({app,selector,args,replaceByURL})->
       args={} if not args
       replaceByURL=true if not replaceByURL?
       @defaultApp=app
       @defaultContainer=selector
       [appName,view]=app.split(':')
       @containerApps[selector].__destroy__() if @containerApps[selector]? and appName!= @containerApps[selector].__app__
       storeCA= (a)=>
          @currentView=a
          @containerApps[selector]=a
          # загружаем приложение, указанное в адресной строке
          if replaceByURL
             hash=window.location.hash.split('#')
             return if not hash[1]
             [app,args]=hash[1].substr(1).split('/')
             return if not app or app==@defaultApp
             @repl({app,cont:@defaultContainer,args:JAFW.Url.decode(args)})
       # сохраняем последнее состояние представления, если есть функция сохранения
       self.history.pushState?(@defaultContainer,(if @currentView?.__printable__? then @currentView.__printable__ else null),"/#/#{app}/#{JAFW.Url.encode(args)}")
       JAFW.run(@defaultContainer,app,args,storeCA)
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
JAFW.run=(selector,appSignature,args,onload,parentId=null)->
    [ns,name]=appSignature.split('::')
    [ns,name]=['',ns] if not name
    [appName,blockName]=name.split(':')
    appName=if ns then ns+':'+appName else appName
    appAccess=appName.replace(':','_')
    if appAccess not of JAFW.Apps._registered
        JAFW.Apps.__Register(appAccess)
    JAFW.Apps[appAccess].put(selector,blockName,args,parentId,onload)

JAFW.__Register('Ajax',Ajax)
JAFW.__Register('Apps',AppEnvironment)
JAFW.__Register('Launcher',Launcher)