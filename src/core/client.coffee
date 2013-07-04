# CLIENT SIDE
##
# Среда запуска приложений
##
debugRnd=->
   return if window.inSideConf?.debug then Math.round(Math.random()*100) else ''

class AppEnvironment
   _styles :         {}
   _registered :     {}
   _selectorHandlers : {}
   _initializers :          {}
   _runQueue :       []
   _busy :           false
   _running :        {}
   _dirty :          false


   _kill : (selector)->
      appId=AppEnvironment::_selectorHandlers[selector]
      AppEnvironment::_running[appId]?.__destroy__()


   _garbageCollect : ()->
      if AppEnvironment::_dirty
         for appId,app of AppEnvironment::_running
            continue if not app.__container__?
            if not app.__container__.parentNode and app.__disposable__
               console.log('Garbage collector destroying app: ' + app.__name__ + ' at container ' + appId)
               app.__destroy__()
               delete AppEnvironment::_running[appId]
         AppEnvironment::_dirty = false


   _load : (appName, selector, args, onLoad)->
      if AppEnvironment::_registered[appName]?
         onLoad(appName, selector, args)
      else
         AppEnvironment::_initializers[appName] = (appName)-> onLoad(appName, selector, args)
         script = document.createElement("script");
         script.type = "text/javascript";
         script.src = """#{inSideConf.app_dir}/#{appName.split(':').join('/')}.jsb.js?#{debugRnd()}"""
         script.onerror = ->
            AppEnvironment::_busy = false
         script.async = true
         document.getElementsByTagName('head')[0].appendChild(script)


   _setupClass:(body)->
      body.kill = (selector)->AppEnvironment::_kill(selector)
      body.run = (selector, appName, args, onload)->
         inSide.run(appName, selector, args, onload, @__id__)

      body.__oncreate__ = ((r, args)->r(args)) if not body.__oncreate__?
      body.__onrender__ = ((r, args)->r(args)) if not body.__onrender__?
      body.__init__ = body.init
      body.__destroy__ = (calledByParent = false)->
         # удаляем обработчик из списка потомков родителя
         if @__parent__ and (not calledByParent)
            children=@__parent__.__children__
            for child,childIndex in children
               if child.__id__ == @__id__
                  @__parent__.__children__.splice(childIndex, 1)
                  break
         DISCONNECT('*', '*', @)
         # Пользовательский деструктор
         @destroy() if @destroy?
         @__super__?.destroy?()
         return if not AppEnvironment::_running[@__id__]?
         # Вызов деструкторов потомков
         for c in AppEnvironment::_running[@__id__].__children__
            c.__destroy__(true)
         if @__container__?.innerHTML?
            @__container__.innerHTML = ''
         delete AppEnvironment::_running[@__id__]


   _setupInstance:(instance, selector, args, parentId, onload)->

      if typeof(selector) == typeof({})
         container=selector
         disposable=false
      else
         container=if selector then $s(selector) else null
         disposable=true
         AppEnvironment::_kill(selector)

      instanceId=inSide.__nextID('inSideHandler')
      AppEnvironment::_running[instanceId] = instance
      AppEnvironment::_selectorHandlers[selector] = instanceId

      args.config = inSideConf

      instance.__id__ = instanceId
      instance.__winId__ = 0 # main window
      instance.__parent__ = AppEnvironment::_running[parentId]
      instance.__children__ = []
      instance.__container__ = container
      instance.__disposable__ = disposable
      instance.__args__ = args

      instance.toString = -> @__name__
      if parentId of AppEnvironment::_running
         AppEnvironment::_running[parentId].__children__.push(instance)

      init=(args,noreload=true)->
         if instance.__container__
            installDOMWrappers(instance, container)

            if instance.__template__
               style=if instance.__style__? then instance.__style__ else ''
               instance.__container__.innerHTML = style + instance.__template__(args, jade)
            AppEnvironment::_dirty = true
            if instance.__events__
               instance.setupEvents(instance.__events__)

         if instance.__connections__
            INIT_CONNECTIONS(instance,instance.__connections__)
         if instance.__init__
            instance.__init__()
         if noreload
            onload?(instance)

      instance.__reload__ = ((init, args)->->return instance.__onrender__(((args)->init(args,false)), args))(init, args)
      instance.__oncreate__(((args)->instance.__onrender__(init, args)), args)

   register:(appName, body)->
      logDebug(appName)
      if appName in AppEnvironment::_registered
         throw('Application already registered')
      AppEnvironment::_setupClass(body)

      AppEnvironment::_registered[appName] = {
         body: body,
         constructor: (bindObject)->
            bindObject = @ if not bindObject
            body = AppEnvironment::_registered[appName].body
            for property, value of body
               @[property] = if typeof(value) == typeof(->) then value.bind(bindObject) else value
            if body.__extends__
               @__super__ = new AppEnvironment::_registered[body.__extends__].constructor(@)
            return undefined
         run:(selector = null, args = {}, parentId = null, onload = null)->
            AppEnvironment::_garbageCollect(@)
            AppEnvironment::_setupInstance(new AppEnvironment::_registered[appName].constructor(), selector, args, parentId, onload)
            AppEnvironment::_busy = false
            if AppEnvironment::_runQueue.length
               nextargs=AppEnvironment::_runQueue.shift()
               inSide.run.apply(AppEnvironment::_registered[nextargs[0]], nextargs)
      }

      if body.__extends__?
         AppEnvironment::_load(body.__extends__, null, {}, =>
            extendable=AppEnvironment::_registered[appName].body
            for property,value of AppEnvironment::_registered[body.__extends__].body
               extendable[property] = value if not extendable[property]?
            AppEnvironment::_initializers[appName]?(appName)
         )
      else
         AppEnvironment::_initializers[appName]?(appName)


##
# АСИНХРОННАЯ ПЕРЕДАЧА ДАННЫХ
##
class Ajax
   __id__:'ajax'
   constructor:->
      CONNECT 'inSide.Ajax.post',(({url,data})=>@get(url,data)),@
      CONNECT 'inSide.Ajax.get',(({url,data})=>@get(url,data)),@
      CONNECT 'inSide.Ajax.request',(({method,url,data})=>@get(method,url,data)),@

   # Отправка GET-запроса на сервер
   # sUrl - URL, на который отправится запрос
   # oData - объект данных
   # fSuccess/fError - обработчики успешного/ошибочного запроса
   get :     (sUrl, oData, fSuccess, fError)->Ajax::request('GET', sUrl, oData, fSuccess, fError)
   getJSON: (sUrl, oData, fSuccess, fError)->Ajax::get(sUrl, oData, ((r)->fSuccess(JSON.parse(r.responseText))), fError)
   # Отправка POST-запроса на сервер
   # sUrl - URL, на который отправится запрос
   # oData - объект данных
   # fSuccess/fError - обработчики успешного/ошибочного запроса
   post :    (sUrl, oData, fSuccess, fError)->Ajax::request('POST', sUrl, oData, fSuccess, fError)
   postJSON: (sUrl, oData, fSuccess, fError)->Ajax::post(sUrl, oData, ((r)->fSuccess(JSON.parse(r.responseText))), fError)
   # Отправка запроса на сервер
   # sMethod - тип запроса (GET/POST)
   # sUrl - URL, на который отправится запрос
   # oData - объект данных
   # fSuccess/fError - обработчики успешного/ошибочного запроса
   request : (sMethod, sUrl, oData, fSuccess, fError)->
      request=new XMLHttpRequest()
      request.onreadystatechange = ->
         if request.readyState == 4
            # Если не произошло ошибок на протокольном уровне, выполняем fSuccess, иначе fError
            handler=if request.status == 200 then fSuccess else fError
            handler?(request)
      requestData=inSide.Url.encode oData
      # Если метод - GET, кладем данные с строку запроса
      if sMethod == 'GET'
         if requestData
            sUrl += "?#{requestData}"
         requestData = null
      # Выполнение асинхронного запроса
      request.open(sMethod, sUrl, true);
      # Заголовок для POST
      request.setRequestHeader("Content-type", "application/x-www-form-urlencoded") if sMethod == 'POST'
      request.send(requestData)

# Вид URL: #/appName:view/urlencode(param1)/...
# Запуск взаимоисключающих приложений в один контейнер
class Launcher
   toString : ->'appLauncher'
   constructor : ()->
      CONNECT('LAUNCHER_PUSH', 'push', @)
      CONNECT('LAUNCHER_REPLACE', 'push', @)
      CONNECT('LAUNCHER_BACK', 'back', @)
      CONNECT('LAUNCHER_START', 'start', @)
      @defaultContainer = '#inSideContainer'
      @defaultApp = 'Main:index'
      @layout = 'Main:layout'
      @currentView = null
      @storedStates = {}
      # обработчик изменения хеша в адресной строке
      self.onhashchange = (e)=>
         if e.newURL
            hash=e.newURL.split('#!')
         else
            hash=window.location.hash.split('#!')
         return if hash[1]==@hash
         @hash=hash[1]
         if hash[1]
            [app, args]=hash[1].substr(1).split('/')
         else
            app=@defaultApp
            args=""
         EMIT 'inSide.launcher.hashChange', {app}
         AppEnvironment::_kill(@defaultContainer)
         inSide.run(app, @defaultContainer, inSide.Url.decode(args))

   start :       ({layout,app,selector,args})->
      args={} if not args
      @layout=layout
      @defaultApp = app
      @defaultContainer = selector
      inSide.run layout, '#inSideContainer', args, =>
         hash=window.location.hash.split('#!')
         if not hash[1]
            app = @defaultApp
            args=''
         else
            [app, args]=hash[1].substr(1).split('/')
            if not app
               app = @defaultApp
               args=''
         self.onhashchange({newURL : window.location.pathname + "#!/#{app}/#{args}"})

   back : ({defaultApp, defaultArgs})->
      if self.history.state
         self.history.back()
      else
         @push({app:defaultApp, cont:@defaultContainer, args:defaultArgs})

   push :        ({cont,app,args})->
      self.history.pushState?(cont, (if @currentView?.__printable__? then @currentView.__printable__ else null),
         window.location.pathname + "#!/#{app}/#{inSide.Url.encode(args)}")
      self.onhashchange({newURL : window.location.pathname + "#!/#{app}/#{inSide.Url.encode(args)}"})
##
# Запуск блока приложения
##
containerApps = null
inSide.run = (appName, selector, args, onload, parentId = null)->
   doRun=(appName, selector, args)->
      AppEnvironment::_registered[appName].run(selector, args, parentId, onload)
   if AppEnvironment::_busy == true
      AppEnvironment::_runQueue.push([appName, selector, args, @__id__, onload])
      return
   if appName not of AppEnvironment::_registered
      AppEnvironment::_busy=true
      AppEnvironment::_load(appName, selector, args, doRun)
   else
      doRun(appName, selector, args)

inSide.__Register('Ajax', Ajax)
inSide.__Register('Apps', AppEnvironment)
inSide.__Register('Launcher', Launcher)
